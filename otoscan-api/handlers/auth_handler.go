package handlers

import (
	"strings"
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// RegisterRequest defines expected payload for user registration
type RegisterRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Phone    string `json:"phone"`
	Address  string `json:"address"`
	Role     string `json:"role"`
}

// LoginRequest defines expected payload for login authentication
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Register handles user registration with hashed password and auto JWT issue
func Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid JSON request body",
		})
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.Password = strings.TrimSpace(req.Password)

	if req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Name is required",
		})
	}
	if req.Email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Email is required",
		})
	}
	if len(req.Password) < 6 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Password must be at least 6 characters long",
		})
	}

	// Force role to 'user' for public registration unless requester is an authenticated admin
	callerRole, _ := c.Locals("role").(string)
	if !strings.EqualFold(callerRole, "admin") {
		req.Role = "user"
	} else if req.Role == "" {
		req.Role = "user"
	}

	if config.DB != nil {
		var existingCount int64
		config.DB.Model(&models.User{}).Where("LOWER(email) = ?", req.Email).Count(&existingCount)
		if existingCount > 0 {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Email address is already registered",
			})
		}
	}

	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process password encryption",
		})
	}

	newUser := models.User{
		ID:        uuid.New().String(),
		Name:      req.Name,
		Email:     req.Email,
		Password:  hashedPassword,
		Role:      req.Role,
		Phone:     req.Phone,
		Address:   req.Address,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if config.DB != nil {
		if err := config.DB.Create(&newUser).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Failed to save user account: " + err.Error(),
			})
		}
	}

	token, expiresAt, err := utils.GenerateToken(newUser.ID, newUser.Email, newUser.Role)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "User registered but failed to generate token",
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":    "success",
		"message":   "User registered successfully",
		"token":     token,
		"expiresAt": expiresAt,
		"user":      newUser,
	})
}

// Login authenticates email and password, returning JWT token and user profile
func Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid JSON request body",
		})
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.Password = strings.TrimSpace(req.Password)

	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Email and password are required",
		})
	}

	var user models.User
	if config.DB != nil {
		err := config.DB.Preload("Vehicles").First(&user, "LOWER(email) = ?", req.Email).Error
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"status":  "error",
				"message": "Invalid email or password",
			})
		}
	} else {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database connection is not available",
		})
	}

	if !utils.CheckPasswordHash(req.Password, user.Password) {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid email or password",
		})
	}

	// Auto-upgrade plain text password to bcrypt hash in database for existing legacy users
	if user.Password == req.Password {
		if newHash, err := utils.HashPassword(req.Password); err == nil {
			config.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("password", newHash)
			user.Password = newHash
		}
	}

	user.VehicleCount = len(user.Vehicles)

	token, expiresAt, err := utils.GenerateToken(user.ID, user.Email, user.Role)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to generate authentication token",
		})
	}

	return c.JSON(fiber.Map{
		"status":    "success",
		"message":   "Login successful",
		"token":     token,
		"expiresAt": expiresAt,
		"user":      user,
	})
}

// GetProfile returns the authenticated user profile based on JWT token
func GetProfile(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"status":  "error",
			"message": "Unauthorized user context",
		})
	}

	var user models.User
	if config.DB != nil {
		err := config.DB.Preload("Vehicles").First(&user, "id = ?", userID).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "User profile not found",
			})
		}
		user.VehicleCount = len(user.Vehicles)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   user,
	})
}

// UpdateProfileRequest defines editable fields for self profile update
type UpdateProfileRequest struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Phone    string `json:"phone"`
	Address  string `json:"address"`
}

// UpdateProfile allows authenticated users to update their own Name, Password, Phone, and Address
func UpdateProfile(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"status":  "error",
			"message": "Unauthorized user context",
		})
	}

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	var user models.User
	if err := config.DB.First(&user, "id = ?", userID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "User profile not found",
		})
	}

	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid profile update payload",
		})
	}

	if strings.TrimSpace(req.Name) != "" {
		user.Name = strings.TrimSpace(req.Name)
	}
	if strings.TrimSpace(req.Phone) != "" {
		user.Phone = strings.TrimSpace(req.Phone)
	}
	if strings.TrimSpace(req.Address) != "" {
		user.Address = strings.TrimSpace(req.Address)
	}
	if strings.TrimSpace(req.Password) != "" {
		if len(req.Password) < 6 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"status":  "error",
				"message": "Password minimal 6 karakter",
			})
		}
		hashedPass, err := utils.HashPassword(strings.TrimSpace(req.Password))
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal memproses enkripsi password baru",
			})
		}
		user.Password = hashedPass
	}
	user.UpdatedAt = time.Now()

	if err := config.DB.Save(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memperbarui profil: " + err.Error(),
		})
	}

	config.DB.Preload("Vehicles").First(&user, "id = ?", user.ID)
	user.VehicleCount = len(user.Vehicles)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Profil berhasil diperbarui",
		"data":    user,
	})
}

// Logout handles user logout action
func Logout(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Logout successful. Please clear token from client storage.",
	})
}
