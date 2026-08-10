package models

import (
	"time"

	"gorm.io/gorm"
)

// InspectionPhoto represents an uploaded vehicle photo for a specific inspection and angle
type InspectionPhoto struct {
	ID             string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	InspectionID   string         `gorm:"type:varchar(36);not null;index" json:"inspectionId"`
	AngleCaptureID string         `gorm:"type:varchar(36);not null;index" json:"angleCaptureId"`
	ImagePath      string         `gorm:"type:text;not null" json:"imagePath"`
	CreatedAt      time.Time      `json:"createdAt"`
	UpdatedAt      time.Time      `json:"updatedAt"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	AngleCapture *AngleCapture `gorm:"foreignKey:AngleCaptureID" json:"angleCapture,omitempty"`
	Damages      []DamageItem  `gorm:"foreignKey:InspectionPhotoID;constraint:OnDelete:CASCADE;" json:"damages,omitempty"`
}
