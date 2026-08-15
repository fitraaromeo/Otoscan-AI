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

// GetInspectionStatuses returns list of master inspection statuses from PostgreSQL
func GetInspectionStatuses(c *fiber.Ctx) error {
	var statuses []models.InspectionStatus
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.InspectionStatus{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Order("created_at asc").Limit(limit).Offset(offset).Find(&statuses)
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(statuses),
		"pagination": meta,
		"data":       statuses,
	})
}

// CreateInspectionStatus handles creating a new master inspection status
func CreateInspectionStatus(c *fiber.Ctx) error {
	var is models.InspectionStatus
	if err := c.BodyParser(&is); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if is.Code == "" || is.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Code dan Name status inspeksi wajib diisi",
		})
	}

	is.ID = uuid.New().String()
	is.CreatedAt = time.Now()
	is.UpdatedAt = time.Now()

	if config.DB != nil {
		if err := config.DB.Create(&is).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Kode status inspeksi sudah ada",
			})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Status inspeksi berhasil ditambahkan",
		"data":    is,
	})
}

// DeleteInspectionStatus handles soft deleting a master inspection status definition
func DeleteInspectionStatus(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.InspectionStatus{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus status inspeksi",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Status inspeksi berhasil dihapus (soft delete)",
	})
}

// UpdateDamageType handles updating a damage type master record
func UpdateDamageType(c *fiber.Ctx) error {
	id := c.Params("id")
	var dt models.DamageType

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	if err := config.DB.First(&dt, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Jenis kerusakan tidak ditemukan",
		})
	}

	var req models.DamageType
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if req.Code != "" {
		dt.Code = req.Code
	}
	if req.Name != "" {
		dt.Name = req.Name
	}
	dt.Description = req.Description
	dt.UpdatedAt = time.Now()

	if err := config.DB.Save(&dt).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memperbarui jenis kerusakan: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Jenis kerusakan berhasil diperbarui",
		"data":    dt,
	})
}

// UpdateAngleCapture handles updating a master angle capture definition
func UpdateAngleCapture(c *fiber.Ctx) error {
	id := c.Params("id")
	var ac models.AngleCapture

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	if err := config.DB.First(&ac, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Sudut pemindaian tidak ditemukan",
		})
	}

	var req models.AngleCapture
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if req.Name != "" {
		ac.Name = req.Name
	}
	ac.Description = req.Description
	ac.UpdatedAt = time.Now()

	if err := config.DB.Save(&ac).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memperbarui sudut pemindaian: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Sudut pemindaian berhasil diperbarui",
		"data":    ac,
	})
}

// UpdateInspectionStatus handles updating a master inspection status
func UpdateInspectionStatus(c *fiber.Ctx) error {
	id := c.Params("id")
	var is models.InspectionStatus

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database not connected",
		})
	}

	if err := config.DB.First(&is, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Status inspeksi tidak ditemukan",
		})
	}

	var req models.InspectionStatus
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON tidak valid",
		})
	}

	if req.Code != "" {
		is.Code = req.Code
	}
	if req.Name != "" {
		is.Name = req.Name
	}
	is.Description = req.Description
	is.UpdatedAt = time.Now()

	if err := config.DB.Save(&is).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memperbarui status inspeksi: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Status inspeksi berhasil diperbarui",
		"data":    is,
	})
}
