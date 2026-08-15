package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"otoscan-api/config"
	"otoscan-api/models"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// YOLOPredictionResult represents output payload from Python YOLOv12 FastAPI microservice
type YOLOPredictionResult struct {
	Status             string         `json:"status"`
	TotalDetections    int            `json:"total_detections"`
	AnnotatedImagePath string         `json:"annotated_image_path,omitempty"`
	Summary            map[string]int `json:"summary"`
	Predictions        []struct {
		ClassCode  string    `json:"class_code"`
		ClassID    int       `json:"class_id"`
		Confidence float64   `json:"confidence"`
		BoxXYXY    []float64 `json:"box_xyxy"`
	} `json:"predictions"`
}

func cleanFirstWord(s string) string {
	s = strings.TrimSpace(s)
	parts := strings.Fields(s)
	if len(parts) > 0 {
		s = parts[0]
	}
	s = strings.ToLower(s)
	reg := regexp.MustCompile(`[^a-z0-9]+`)
	cleaned := reg.ReplaceAllString(s, "")
	if cleaned == "" {
		return "client"
	}
	return cleaned
}

func cleanAngleShort(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = strings.ReplaceAll(s, "tampak", "")
	s = strings.TrimSpace(s)
	reg := regexp.MustCompile(`[^a-z0-9]+`)
	cleaned := reg.ReplaceAllString(s, "")
	if cleaned == "" {
		return "angle"
	}
	return cleaned
}

func getShortID(idStr string) string {
	clean := strings.ReplaceAll(idStr, "-", "")
	if len(clean) >= 8 {
		return clean[:8]
	}
	return idStr
}

// DetectDamageYOLOv12 receives image upload, calls Python YOLOv12 microservice, and saves detections to PostgreSQL
func DetectDamageYOLOv12(c *fiber.Ctx) error {
	inspectionID := c.Params("id")
	angleCaptureID := c.FormValue("angleCaptureId")
	angleName := c.FormValue("angleName") // e.g. Tampak Depan, Tampak Belakang

	fileHeader, err := c.FormFile("image")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "File foto kendaraan (image) wajib diunggah",
		})
	}

	file, err := fileHeader.Open()
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal membaca file foto kendaraan",
		})
	}
	defer file.Close()

	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memproses byte file gambar",
		})
	}

	// Resolve AngleCaptureID & Client Name if missing
	var clientNameStr string = "client"
	var angleNameStr string = angleName

	if config.DB != nil {
		var ins models.Inspection
		if err := config.DB.Preload("Vehicle.User").First(&ins, "id = ?", inspectionID).Error; err == nil {
			if ins.Vehicle != nil && ins.Vehicle.User != nil && ins.Vehicle.User.Name != "" {
				clientNameStr = ins.Vehicle.User.Name
			}
		}

		if angleCaptureID != "" {
			var ac models.AngleCapture
			if err := config.DB.First(&ac, "id = ?", angleCaptureID).Error; err == nil && ac.Name != "" {
				angleNameStr = ac.Name
			}
		} else if angleName != "" {
			var ac models.AngleCapture
			if err := config.DB.Where("name ILIKE ?", "%"+angleName+"%").First(&ac).Error; err == nil {
				angleCaptureID = ac.ID
				angleNameStr = ac.Name
			}
		}
	}

	// Fallback to first master angle if still empty
	if config.DB != nil && angleCaptureID == "" {
		var ac models.AngleCapture
		if err := config.DB.Order("created_at asc").First(&ac).Error; err == nil {
			angleCaptureID = ac.ID
			if angleNameStr == "" {
				angleNameStr = ac.Name
			}
		}
	}

	cleanAngle := cleanAngleShort(angleNameStr)
	cleanClient := cleanFirstWord(clientNameStr)
	shortID := getShortID(inspectionID)
	ext := filepath.Ext(fileHeader.Filename)
	if ext == "" {
		ext = ".jpg"
	}

	// Format: angle_firstclientname_shortid.ext (e.g. depan_fitra_0d871803.jpg)
	fileName := fmt.Sprintf("%s_%s_%s%s", cleanAngle, cleanClient, shortID, ext)
	resultFileName := fmt.Sprintf("result_%s_%s_%s%s", cleanAngle, cleanClient, shortID, ext)

	// Simpan file foto fisik ke direktori ./uploads/inspections/
	uploadDir := "./uploads/inspections"
	_ = os.MkdirAll(uploadDir, os.ModePerm)
	localFilePath := fmt.Sprintf("%s/%s", uploadDir, fileName)
	publicURLPath := fmt.Sprintf("/uploads/inspections/%s", fileName)

	if err := c.SaveFile(fileHeader, localFilePath); err != nil {
		fmt.Printf("âš ï¸ Gagal menyimpan file gambar ke disk: %v\n", err)
	}

	// Simpan record foto ke tabel inspection_photos
	inspectionPhoto := models.InspectionPhoto{
		ID:             uuid.New().String(),
		InspectionID:   inspectionID,
		AngleCaptureID: angleCaptureID,
		ImagePath:      publicURLPath,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	if config.DB != nil {
		config.DB.Create(&inspectionPhoto)
	}

	aiServiceURL := os.Getenv("YOLO_SERVICE_URL")
	if aiServiceURL == "" {
		aiServiceURL = "http://localhost:5000/predict"
	}

	// Call Python YOLOv12 Microservice with custom result filename
	yoloResult, err := callYOLOv12Service(aiServiceURL, fileHeader.Filename, fileBytes, resultFileName)
	if err != nil {
		logError := fmt.Sprintf("âš ï¸ YOLOv12 AI Service offline / error: %v", err)
		fmt.Println(logError)
	}

	var savedDamages []models.DamageItem

	if config.DB != nil && yoloResult != nil && len(yoloResult.Summary) > 0 {
		for classCode, quantity := range yoloResult.Summary {
			var dt models.DamageType
			if err := config.DB.Where("code = ?", classCode).First(&dt).Error; err == nil {
				// Aggregate bounding box coordinates for matching predictions
				var bboxes [][]float64
				for _, pred := range yoloResult.Predictions {
					if pred.ClassCode == classCode {
						bboxes = append(bboxes, pred.BoxXYXY)
					}
				}
				bboxJSON, _ := json.Marshal(bboxes)

				annotatedPath := yoloResult.AnnotatedImagePath
				if annotatedPath == "" {
					annotatedPath = publicURLPath // fallback to original uploaded image
				}

				damageItem := models.DamageItem{
					ID:                 uuid.New().String(),
					InspectionPhotoID:  inspectionPhoto.ID,
					DamageTypeID:       dt.ID,
					Quantity:           quantity,
					BboxCoordinates:    string(bboxJSON),
					AnnotatedImagePath: annotatedPath,
					CreatedAt:          time.Now(),
					UpdatedAt:          time.Now(),
				}
				config.DB.Create(&damageItem)
				damageItem.DamageType = &dt
				savedDamages = append(savedDamages, damageItem)
			}
		}
	}

	inspectionPhoto.Damages = savedDamages

	return c.JSON(fiber.Map{
		"status":          "success",
		"message":         "Foto berhasil diunggah & inferensi YOLOv12 selesai",
		"inspectionId":    inspectionID,
		"angleCaptureId":  angleCaptureID,
		"photo":           inspectionPhoto,
		"totalDetections": len(savedDamages),
		"rawPredictions":  yoloResult,
		"savedDamages":    savedDamages,
	})
}

func callYOLOv12Service(url string, filename string, fileBytes []byte, outputFilename string) (*YOLOPredictionResult, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	if outputFilename != "" {
		_ = writer.WriteField("output_filename", outputFilename)
	}

	part, err := writer.CreateFormFile("file", filename)
	if err != nil {
		return nil, err
	}

	_, err = part.Write(fileBytes)
	if err != nil {
		return nil, err
	}

	err = writer.Close()
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("YOLOv12 service returned status %d: %s", resp.StatusCode, string(respBytes))
	}

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var result YOLOPredictionResult
	if err := json.Unmarshal(respBytes, &result); err != nil {
		return nil, err
	}

	return &result, nil
}


// DetectDamagePreview runs YOLOv12 on the uploaded frame and returns predictions without saving to database
func DetectDamagePreview(c *fiber.Ctx) error {
	fileHeader, err := c.FormFile("image")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "File foto kendaraan (image) wajib diunggah",
		})
	}

	file, err := fileHeader.Open()
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal membaca file foto kendaraan",
		})
	}
	defer file.Close()

	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Gagal memproses byte file gambar",
		})
	}

	aiServiceURL := os.Getenv("YOLO_SERVICE_URL")
	if aiServiceURL == "" {
		aiServiceURL = "http://localhost:5000/predict"
	}

	// Call Python YOLOv12 Microservice. Since it's a preview, we don't need to specify outputFilename for saving.
	yoloResult, err := callYOLOv12Service(aiServiceURL, fileHeader.Filename, fileBytes, "")
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": fmt.Sprintf("YOLOv12 AI Service error: %v", err),
		})
	}

	type DamagePreviewItem struct {
		ID         string  `json:"id"`
		Type       string  `json:"type"`
		Confidence float64 `json:"confidence"`
		X          float64 `json:"x"`
		Y          float64 `json:"y"`
		Width      float64 `json:"width"`
		Height     float64 `json:"height"`
	}

	var damages []DamagePreviewItem
	for idx, pred := range yoloResult.Predictions {
		if len(pred.BoxXYXY) >= 4 {
			x1 := pred.BoxXYXY[0]
			y1 := pred.BoxXYXY[1]
			x2 := pred.BoxXYXY[2]
			y2 := pred.BoxXYXY[3]
			damages = append(damages, DamagePreviewItem{
				ID:         fmt.Sprintf("prev-%d-%d", idx, time.Now().UnixNano()),
				Type:       pred.ClassCode,
				Confidence: pred.Confidence,
				X:          x1,
				Y:          y1,
				Width:      x2 - x1,
				Height:     y2 - y1,
			})
		}
	}

	return c.JSON(fiber.Map{
		"status":          "success",
		"predictions":     damages,
		"totalDetections": len(damages),
	})
}
