package handlers

import (
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// GetEmployees returns paginated list of employees from PostgreSQL
func GetEmployees(c *fiber.Ctx) error {
	var employees []models.Employee
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.Employee{}).Count(&total)
		offset := (page - 1) * limit
		config.DB.Order("created_at desc").Limit(limit).Offset(offset).Find(&employees)
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(employees),
		"pagination": meta,
		"data":       employees,
	})
}

// GetEmployeeByID returns single employee detail by ID
func GetEmployeeByID(c *fiber.Ctx) error {
	id := c.Params("id")
	var employee models.Employee

	if config.DB != nil {
		err := config.DB.First(&employee, "id = ?", id).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Data karyawan tidak ditemukan",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   employee,
	})
}

// CreateEmployee handles creation of a new employee
func CreateEmployee(c *fiber.Ctx) error {
	var emp models.Employee
	if err := c.BodyParser(&emp); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format payload JSON karyawan tidak valid",
		})
	}

	if emp.IDKependudukan == "" || emp.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "ID Kependudukan dan Nama karyawan wajib diisi",
		})
	}

	emp.ID = uuid.New().String()
	emp.CreatedAt = time.Now()
	emp.UpdatedAt = time.Now()

	if config.DB != nil {
		if err := config.DB.Create(&emp).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "ID Kependudukan atau Email karyawan sudah terdaftar",
				"error":   err.Error(),
			})
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Data karyawan berhasil ditambahkan",
		"data":    emp,
	})
}

// UpdateEmployee handles updating employee data
func UpdateEmployee(c *fiber.Ctx) error {
	id := c.Params("id")
	var emp models.Employee

	if config.DB == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Database tidak terhubung",
		})
	}

	if err := config.DB.First(&emp, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Data karyawan tidak ditemukan",
		})
	}

	var req models.Employee
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Payload update tidak valid",
		})
	}

	emp.IDKependudukan = req.IDKependudukan
	emp.Name = req.Name
	emp.Email = req.Email
	emp.Phone = req.Phone
	emp.UpdatedAt = time.Now()

	config.DB.Save(&emp)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Data karyawan berhasil diperbarui",
		"data":    emp,
	})
}

// DeleteEmployee handles soft deleting an employee
func DeleteEmployee(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		if err := config.DB.Delete(&models.Employee{}, "id = ?", id).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus data karyawan",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Data karyawan berhasil dihapus",
	})
}
