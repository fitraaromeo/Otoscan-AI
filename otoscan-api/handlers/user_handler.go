package handlers

import (
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// PopulateUserVehicleCount fills the non-persisted VehicleCount field on User
func PopulateUserVehicleCount(user *models.User) {
	if user != nil && user.ID != "" && config.DB != nil {
		var count int64
		config.DB.Model(&models.Vehicle{}).Where("user_id = ?", user.ID).Count(&count)
		user.VehicleCount = int(count)
	}
}

// GetUsers returns paginated list of users / vehicle owners from PostgreSQL with their vehicles preloaded and total vehicleCount
func GetUsers(c *fiber.Ctx) error {
	var users []models.User
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.User{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Preload("Vehicles").Order("created_at desc").Limit(limit).Offset(offset).Find(&users)

		for i := range users {
			users[i].VehicleCount = len(users[i].Vehicles)
		}
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(users),
		"pagination": meta,
		"data":       users,
	})
}

// GetUserByID returns single user detail by ID along with their owned vehicles and vehicleCount
func GetUserByID(c *fiber.Ctx) error {
	id := c.Params("id")
	var user models.User

	if config.DB != nil {
		err := config.DB.Preload("Vehicles").First(&user, "id = ?", id).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Client data not found",
			})
		}
		user.VehicleCount = len(user.Vehicles)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   user,
	})
}

// CreateUser handles creation of a new customer / vehicle owner
func CreateUser(c *fiber.Ctx) error {
	var user models.User
	if err := c.BodyParser(&user); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid JSON payload for client",
		})
	}

	if user.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Full name is required",
		})
	}

	user.ID = uuid.New().String()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	if config.DB != nil {
		if err := config.DB.Create(&user).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Email is already registered",
				"error":   err.Error(),
			})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Client created successfully",
		"data":    user,
	})
}

// UpdateUser handles updating user details
func UpdateUser(c *fiber.Ctx) error {
	id := c.Params("id")
	var user models.User

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	if err := config.DB.First(&user, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Client data not found",
		})
	}

	var req models.User
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid update payload",
		})
	}

	if req.Name != "" {
		user.Name = req.Name
	}
	user.Email = req.Email
	user.Phone = req.Phone
	user.Address = req.Address
	user.UpdatedAt = time.Now()

	if err := config.DB.Select("*").Save(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update client: " + err.Error(),
		})
	}

	config.DB.Preload("Vehicles").First(&user, "id = ?", user.ID)
	user.VehicleCount = len(user.Vehicles)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Client updated successfully",
		"data":    user,
	})
}

// DeleteUser handles soft deleting a user
func DeleteUser(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.User{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Failed to delete client",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Client deleted successfully",
	})
}
