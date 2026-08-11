package handlers

import (
	"otoscan-api/models"

	"gorm.io/gorm"
)

// CascadeSoftDeleteInspection soft-deletes an inspection record along with all related photos and damage items
func CascadeSoftDeleteInspection(tx *gorm.DB, inspectionID string) error {
	var photos []models.InspectionPhoto
	if err := tx.Where("inspection_id = ?", inspectionID).Find(&photos).Error; err == nil {
		for _, photo := range photos {
			// Soft-delete damage items attached to this photo
			tx.Where("inspection_photo_id = ?", photo.ID).Delete(&models.DamageItem{})
		}
		// Soft-delete photos attached to this inspection
		tx.Where("inspection_id = ?", inspectionID).Delete(&models.InspectionPhoto{})
	}
	// Soft-delete the inspection itself
	return tx.Where("id = ?", inspectionID).Delete(&models.Inspection{}).Error
}

// CascadeSoftDeleteVehicle soft-deletes a vehicle record along with all related inspections, photos, and damage items
func CascadeSoftDeleteVehicle(tx *gorm.DB, vehicleID string) error {
	var inspections []models.Inspection
	if err := tx.Where("vehicle_id = ?", vehicleID).Find(&inspections).Error; err == nil {
		for _, inspection := range inspections {
			if err := CascadeSoftDeleteInspection(tx, inspection.ID); err != nil {
				return err
			}
		}
	}
	// Soft-delete the vehicle itself
	return tx.Where("id = ?", vehicleID).Delete(&models.Vehicle{}).Error
}

// CascadeSoftDeleteUser soft-deletes a user/client record along with all related vehicles, inspections, photos, and damage items
func CascadeSoftDeleteUser(tx *gorm.DB, userID string) error {
	var vehicles []models.Vehicle
	if err := tx.Where("user_id = ?", userID).Find(&vehicles).Error; err == nil {
		for _, vehicle := range vehicles {
			if err := CascadeSoftDeleteVehicle(tx, vehicle.ID); err != nil {
				return err
			}
		}
	}
	// Soft-delete the user/client itself
	return tx.Where("id = ?", userID).Delete(&models.User{}).Error
}
