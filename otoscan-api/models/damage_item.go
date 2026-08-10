package models

import (
	"time"

	"gorm.io/gorm"
)

// DamageItem represents YOLOv12 damage analysis item belonging to a specific InspectionPhoto
type DamageItem struct {
	ID                 string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	InspectionPhotoID  string         `gorm:"type:varchar(36);not null;index" json:"inspectionPhotoId"`
	DamageTypeID       string         `gorm:"type:varchar(36);not null;index" json:"damageTypeId"`
	Quantity           int            `gorm:"default:1" json:"quantity"`
	BboxCoordinates    string         `gorm:"type:text" json:"bboxCoordinates,omitempty"`
	AnnotatedImagePath string         `gorm:"type:text" json:"annotatedImagePath,omitempty"`
	CreatedAt          time.Time      `json:"createdAt"`
	UpdatedAt          time.Time      `json:"updatedAt"`
	DeletedAt          gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	InspectionPhoto *InspectionPhoto `gorm:"foreignKey:InspectionPhotoID" json:"inspectionPhoto,omitempty"`
	DamageType      *DamageType      `gorm:"foreignKey:DamageTypeID" json:"damageType,omitempty"`
}
