package models

import (
	"time"

	"gorm.io/gorm"
)

// DamageType represents master data for vehicle damage types
type DamageType struct {
	ID              string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Code            string         `gorm:"type:varchar(50);uniqueIndex;not null" json:"code"`
	Name            string         `gorm:"type:varchar(100);not null" json:"name"`
	DefaultSeverity string         `gorm:"type:varchar(20);default:'ringan'" json:"defaultSeverity"` // ringan, sedang, berat
	Description     string         `gorm:"type:text" json:"description"`
	CreatedAt       time.Time      `json:"createdAt"`
	UpdatedAt       time.Time      `json:"updatedAt"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}
