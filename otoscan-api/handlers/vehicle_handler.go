package handlers

import (
	"strings"
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// VehicleRequest payload supporting both camelCase (userId) and snake_case (user_id)
type VehicleRequest struct {
	UserID    *string `json:"userId"`
	UserIDAlt *string `json:"user_id"`
	Nopol     string  `json:"nopol"`
	Merk      string  `json:"merk"`
	Tipe      string  `json:"tipe"`
	Jenis     string  `json:"jenis"`
}

// GetUserID returns non-empty user ID from either userId or user_id JSON tags
func (req *VehicleRequest) GetUserID() *string {
	if req.UserID != nil && *req.UserID != "" {
		return req.UserID
	}
	if req.UserIDAlt != nil && *req.UserIDAlt != "" {
		return req.UserIDAlt
	}
	return nil
}

// GetVehicles returns paginated list of vehicles from PostgreSQL with preloaded User details
func GetVehicles(c *fiber.Ctx) error {
	var vehicles []models.Vehicle
	var total int64

	page, limit := utils.GetPaginationParams(c)
	userRole, _ := c.Locals("role").(string)
	userID, _ := c.Locals("user_id").(string)

	if config.DB != nil {
		query := config.DB.Model(&models.Vehicle{})
		// If user role is 'user' (non-admin), filter by owned user_id
		if !strings.EqualFold(userRole, "admin") && userID != "" {
			query = query.Where("user_id = ?", userID)
		}

		query.Count(&total)
		offset := (page - 1) * limit
		query.Preload("User").Order("created_at desc").Limit(limit).Offset(offset).Find(&vehicles)

		for i := range vehicles {
			PopulateUserVehicleCount(vehicles[i].User)
		}
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(vehicles),
		"pagination": meta,
		"data":       vehicles,
	})
}

// GetVehicleByID returns single vehicle detail by ID along with owner details
func GetVehicleByID(c *fiber.Ctx) error {
	id := c.Params("id")
	var vehicle models.Vehicle
	userRole, _ := c.Locals("role").(string)
	userID, _ := c.Locals("user_id").(string)

	if config.DB != nil {
		err := config.DB.Preload("User").First(&vehicle, "id = ?", id).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Vehicle data not found",
			})
		}
		// Non-admin user can only view their own vehicle
		if !strings.EqualFold(userRole, "admin") {
			if vehicle.UserID == nil || *vehicle.UserID != userID {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
					"status":  "error",
					"message": "Anda tidak memiliki akses ke data kendaraan ini",
				})
			}
		}
		PopulateUserVehicleCount(vehicle.User)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   vehicle,
	})
}

// CreateVehicle handles creation of a new vehicle record
func CreateVehicle(c *fiber.Ctx) error {
	var req VehicleRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid vehicle JSON payload format",
		})
	}

	if req.Nopol == "" || req.Merk == "" || req.Jenis == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "License plate, make, and category are required",
		})
	}

	userRole, _ := c.Locals("role").(string)
	userID, _ := c.Locals("user_id").(string)

	assignedUserID := req.GetUserID()
	// Non-admin user automatically assigns vehicle to themselves
	if !strings.EqualFold(userRole, "admin") && userID != "" {
		assignedUserID = &userID
	}

	v := models.Vehicle{
		ID:        uuid.New().String(),
		UserID:    assignedUserID,
		Nopol:     req.Nopol,
		Merk:      req.Merk,
		Tipe:      req.Tipe,
		Jenis:     req.Jenis,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if config.DB != nil {
		if err := config.DB.Create(&v).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "License plate is already registered",
				"error":   err.Error(),
			})
		}
		config.DB.Preload("User").First(&v, "id = ?", v.ID)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Vehicle added successfully",
		"data":    v,
	})
}

// UpdateVehicle handles updating vehicle details with duplicate Nopol validation
func UpdateVehicle(c *fiber.Ctx) error {
	id := c.Params("id")
	var v models.Vehicle

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	if err := config.DB.First(&v, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Vehicle data not found",
		})
	}

	userRole, _ := c.Locals("role").(string)
	userID, _ := c.Locals("user_id").(string)

	// Non-admin user can only edit their own vehicle
	if !strings.EqualFold(userRole, "admin") {
		if v.UserID == nil || *v.UserID != userID {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"status":  "error",
				"message": "Anda hanya dapat mengedit kendaraan milik Anda sendiri",
			})
		}
	}

	var req VehicleRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid update payload format",
		})
	}

	// Check if new Nopol already belongs to another vehicle
	if req.Nopol != "" && req.Nopol != v.Nopol {
		var checkExisting models.Vehicle
		if err := config.DB.Where("nopol = ? AND id != ?", req.Nopol, id).First(&checkExisting).Error; err == nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "License plate '" + req.Nopol + "' is already registered to another vehicle",
			})
		}
		v.Nopol = req.Nopol
	}

	if strings.EqualFold(userRole, "admin") {
		v.UserID = req.GetUserID()
	}
	if req.Merk != "" {
		v.Merk = req.Merk
	}
	if req.Tipe != "" {
		v.Tipe = req.Tipe
	}
	if req.Jenis != "" {
		v.Jenis = req.Jenis
	}
	v.UpdatedAt = time.Now()

	if err := config.DB.Select("*").Save(&v).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update vehicle data: " + err.Error(),
		})
	}

	config.DB.Preload("User").First(&v, "id = ?", v.ID)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Vehicle updated successfully",
		"data":    v,
	})
}

// DeleteVehicle handles soft deleting a vehicle record along with all its associated inspections
func DeleteVehicle(c *fiber.Ctx) error {
	userRole, _ := c.Locals("role").(string)
	if !strings.EqualFold(userRole, "admin") {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"status":  "error",
			"message": "Hanya Admin yang memiliki hak akses untuk menghapus data kendaraan",
		})
	}

	id := c.Params("id")

	if config.DB != nil {
		err := config.DB.Transaction(func(tx *gorm.DB) error {
			return CascadeSoftDeleteVehicle(tx, id)
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Failed to delete vehicle and associated inspection data",
				"error":   err.Error(),
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Vehicle and associated inspection data deleted successfully (soft delete)",
	})
}
