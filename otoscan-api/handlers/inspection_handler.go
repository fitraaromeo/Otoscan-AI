package handlers

import (
	"time"

	"otoscan-api/config"
	"otoscan-api/models"
	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// CreateInspection handles creation of a new vehicle inspection record
func CreateInspection(c *fiber.Ctx) error {
	type CreateReq struct {
		VehicleID  string  `json:"vehicleId"`
		Nopol      string  `json:"nopol"`
		Merk       string  `json:"merk"`
		Tipe       string  `json:"tipe"`
		Jenis      string  `json:"jenis"`
		EmployeeID *string `json:"employeeId"`
		Status     string  `json:"status"`
	}

	var req CreateReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Format JSON request tidak valid",
		})
	}

	targetVehicleID := req.VehicleID

	if config.DB != nil {
		// If vehicleId not provided, search or create vehicle by nopol
		if targetVehicleID == "" {
			if req.Nopol == "" {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
					"status":  "error",
					"message": "vehicleId atau nopol kendaraan wajib diisi",
				})
			}

			var vehicle models.Vehicle
			if err := config.DB.Where("nopol = ?", req.Nopol).First(&vehicle).Error; err != nil {
				// Create new vehicle if not found
				vehicle = models.Vehicle{
					ID:        uuid.New().String(),
					Nopol:     req.Nopol,
					Merk:      req.Merk,
					Tipe:      req.Tipe,
					Jenis:     req.Jenis,
					CreatedAt: time.Now(),
					UpdatedAt: time.Now(),
				}
				config.DB.Create(&vehicle)
			}
			targetVehicleID = vehicle.ID
		}
	} else {
		if targetVehicleID == "" {
			targetVehicleID = uuid.New().String()
		}
	}

	inspectionID := uuid.New().String()
	statusVal := req.Status
	if statusVal == "" {
		statusVal = "inProgress"
	}

	newInspection := models.Inspection{
		ID:         inspectionID,
		VehicleID:  targetVehicleID,
		EmployeeID: req.EmployeeID,
		Status:     statusVal,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	if config.DB != nil {
		config.DB.Create(&newInspection)

		// Reload full preloaded Inspection record
		var loadedInspection models.Inspection
		config.DB.Preload("Vehicle").
			Preload("Vehicle.User").
			Preload("Employee").
			Preload("Photos").
			First(&loadedInspection, "id = ?", inspectionID)

		if loadedInspection.Vehicle != nil {
			PopulateUserVehicleCount(loadedInspection.Vehicle.User)
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"status":  "success",
			"message": "Inspeksi kendaraan berhasil dibuat",
			"data":    loadedInspection,
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Inspeksi kendaraan berhasil dibuat",
		"data":    newInspection,
	})
}

// GetInspections returns paginated inspection records from PostgreSQL with preloaded relations
func GetInspections(c *fiber.Ctx) error {
	var inspections []models.Inspection
	var total int64

	page, limit := utils.GetPaginationParams(c)

	if config.DB != nil {
		config.DB.Model(&models.Inspection{}).Count(&total)
		offset := (page - 1) * limit

		config.DB.Preload("Vehicle").
			Preload("Vehicle.User").
			Preload("Employee").
			Preload("Photos").
			Preload("Photos.AngleCapture").
			Preload("Photos.Damages").
			Preload("Photos.Damages.DamageType").
			Order("created_at desc").
			Limit(limit).
			Offset(offset).
			Find(&inspections)

		for i := range inspections {
			if inspections[i].Vehicle != nil {
				PopulateUserVehicleCount(inspections[i].Vehicle.User)
			}
		}
	}

	meta := utils.BuildPaginationMeta(total, page, limit)

	return c.JSON(fiber.Map{
		"status":     "success",
		"count":      len(inspections),
		"pagination": meta,
		"data":       inspections,
	})
}

// GetInspectionByID returns single inspection detail with full preloaded relations
func GetInspectionByID(c *fiber.Ctx) error {
	id := c.Params("id")
	var inspection models.Inspection

	if config.DB != nil {
		err := config.DB.Preload("Vehicle").
			Preload("Vehicle.User").
			Preload("Employee").
			Preload("Photos").
			Preload("Photos.AngleCapture").
			Preload("Photos.Damages").
			Preload("Photos.Damages.DamageType").
			First(&inspection, "id = ?", id).Error
		if err != nil {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Data inspeksi tidak ditemukan",
			})
		}
		if inspection.Vehicle != nil {
			PopulateUserVehicleCount(inspection.Vehicle.User)
		}
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   inspection,
	})
}

// DeleteInspection handles soft deleting an inspection record and all its photos & damage items
func DeleteInspection(c *fiber.Ctx) error {
	id := c.Params("id")

	if config.DB != nil {
		err := config.DB.Transaction(func(tx *gorm.DB) error {
			return CascadeSoftDeleteInspection(tx, id)
		})
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus data inspeksi dan foto terkait",
				"error":   err.Error(),
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Data inspeksi dan foto terkait berhasil dihapus (soft delete)",
	})
}

// AddDamageItem handles adding damage record belonging to an InspectionPhoto
func AddDamageItem(c *fiber.Ctx) error {
	inspectionID := c.Params("id")

	type DamageReq struct {
		InspectionPhotoID  string `json:"inspectionPhotoId"`
		AngleCaptureID     string `json:"angleCaptureId"`
		AngleName          string `json:"angleName"` // fallback e.g. Tampak Depan
		DamageTypeID       string `json:"damageTypeId"`
		DamageCode         string `json:"damageCode"` // fallback e.g. scratch, dent
		Quantity           int    `json:"quantity"`
		BboxCoordinates    string `json:"bboxCoordinates"`
		AnnotatedImagePath string `json:"annotatedImagePath"`
	}

	var req DamageReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Payload damage item tidak valid",
		})
	}

	if req.Quantity <= 0 {
		req.Quantity = 1
	}

	photoID := req.InspectionPhotoID
	damageTypeID := req.DamageTypeID

	if config.DB != nil {
		// Resolve InspectionPhotoID if missing
		if photoID == "" {
			angleCaptureID := req.AngleCaptureID
			if angleCaptureID == "" && req.AngleName != "" {
				var ac models.AngleCapture
				if err := config.DB.Where("name ILIKE ?", "%"+req.AngleName+"%").First(&ac).Error; err == nil {
					angleCaptureID = ac.ID
				}
			}
			if angleCaptureID == "" {
				var ac models.AngleCapture
				if err := config.DB.Order("created_at asc").First(&ac).Error; err == nil {
					angleCaptureID = ac.ID
				}
			}

			var photo models.InspectionPhoto
			if err := config.DB.Where("inspection_id = ? AND angle_capture_id = ?", inspectionID, angleCaptureID).First(&photo).Error; err != nil {
				// Create placeholder InspectionPhoto if none exists
				photo = models.InspectionPhoto{
					ID:             uuid.New().String(),
					InspectionID:   inspectionID,
					AngleCaptureID: angleCaptureID,
					ImagePath:      "",
					CreatedAt:      time.Now(),
					UpdatedAt:      time.Now(),
				}
				config.DB.Create(&photo)
			}
			photoID = photo.ID
		}

		// Resolve DamageTypeID if missing
		if damageTypeID == "" && req.DamageCode != "" {
			var dt models.DamageType
			if err := config.DB.Where("code = ?", req.DamageCode).First(&dt).Error; err == nil {
				damageTypeID = dt.ID
			}
		}
	}

	if photoID == "" || damageTypeID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "inspectionPhotoId dan damageTypeId (atau damageCode) wajib diisi",
		})
	}

	newDamage := models.DamageItem{
		ID:                 uuid.New().String(),
		InspectionPhotoID:  photoID,
		DamageTypeID:       damageTypeID,
		Quantity:           req.Quantity,
		BboxCoordinates:    req.BboxCoordinates,
		AnnotatedImagePath: req.AnnotatedImagePath,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	if config.DB != nil {
		config.DB.Create(&newDamage)
		config.DB.Preload("DamageType").First(&newDamage, "id = ?", newDamage.ID)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Data temuan kerusakan berhasil disimpan ke PostgreSQL",
		"data":    newDamage,
	})
}

// DeleteDamageItem handles soft deleting a damage item record
func DeleteDamageItem(c *fiber.Ctx) error {
	damageID := c.Params("damageId")

	if config.DB != nil {
		if err := config.DB.Delete(&models.DamageItem{}, "id = ?", damageID).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"status":  "error",
				"message": "Gagal menghapus temuan kerusakan",
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Temuan kerusakan berhasil dihapus (soft delete)",
	})
}
