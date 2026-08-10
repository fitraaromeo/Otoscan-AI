package handlers

import (
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
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

	if config.DB != nil {
		config.DB.Model(&models.Vehicle{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Preload("User").Order("created_at desc").Limit(limit).Offset(offset).Find(&vehicles)

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

	if config.DB != nil {
		err := config.DB.Preload("User").First(&vehicle, "id = ?", id).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Vehicle data not found",
			})
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

	v := models.Vehicle{
		ID:        uuid.New().String(),
		UserID:    req.GetUserID(),
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

	v.UserID = req.GetUserID()
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

// DeleteVehicle handles soft deleting a vehicle record
func DeleteVehicle(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.Vehicle{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Failed to delete vehicle data",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Vehicle deleted successfully",
	})
}
