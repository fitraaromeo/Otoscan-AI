package handlers

import (
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// GetDamageTypes returns paginated list of master damage types from PostgreSQL
func GetDamageTypes(c *fiber.Ctx) error {
	var types []models.DamageType
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.DamageType{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Order("code asc").Limit(limit).Offset(offset).Find(&types)
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(types),
		"pagination": meta,
		"data":       types,
	})
}

// CreateDamageType creates a new master damage type
func CreateDamageType(c *fiber.Ctx) error {
	var dt models.DamageType
	if err := c.BodyParser(&dt); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if dt.Code == "" || dt.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Code dan Name wajib diisi",
		})
	}

	dt.ID = uuid.New().String()
	dt.CreatedAt = time.Now()
	dt.UpdatedAt = time.Now()

	if config.DB != nil {
		if err := config.DB.Create(&dt).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Kode jenis kerusakan sudah ada",
			})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Jenis kerusakan berhasil ditambahkan",
		"data":    dt,
	})
}

// DeleteDamageType handles soft deleting a damage type master record
func DeleteDamageType(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.DamageType{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus jenis kerusakan",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Jenis kerusakan berhasil dihapus (soft delete)",
	})
}

// GetAngleCaptures returns paginated list of master scan angle captures from PostgreSQL
func GetAngleCaptures(c *fiber.Ctx) error {
	var angles []models.AngleCapture
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.AngleCapture{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Order("created_at asc").Limit(limit).Offset(offset).Find(&angles)
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(angles),
		"pagination": meta,
		"data":       angles,
	})
}

// CreateAngleCapture creates a new master angle capture definition
func CreateAngleCapture(c *fiber.Ctx) error {
	var ac models.AngleCapture
	if err := c.BodyParser(&ac); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if ac.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Name wajib diisi",
		})
	}

	ac.ID = uuid.New().String()
	ac.CreatedAt = time.Now()
	ac.UpdatedAt = time.Now()

	if config.DB != nil {
		if err := config.DB.Create(&ac).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Nama sudut pemindaian sudah ada",
			})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Sudut pemindaian berhasil ditambahkan",
		"data":    ac,
	})
}

// DeleteAngleCapture handles soft deleting a master angle capture definition
func DeleteAngleCapture(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.AngleCapture{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus sudut pemindaian",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Sudut pemindaian berhasil dihapus (soft delete)",
	})
}
