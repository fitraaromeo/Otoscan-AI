package models

import (
	"time"

	"gorm.io/gorm"
)

// AngleCapture represents master data for vehicle scan angles (e.g. Tampak Depan, Tampak Belakang, Tampak Samping, Tampak Atas)
type AngleCapture struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Name        string         `gorm:"type:varchar(100);uniqueIndex;not null" json:"name"`
	Description string         `gorm:"type:text" json:"description"`
	CreatedAt   time.Time      `json:"createdAt"`
	UpdatedAt   time.Time      `json:"updatedAt"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}
