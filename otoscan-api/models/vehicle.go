package models

import (
	"time"

	"gorm.io/gorm"
)

// Vehicle represents the master vehicle entity
type Vehicle struct {
	ID        string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID    *string        `gorm:"type:varchar(36);index" json:"userId"`
	Nopol     string         `gorm:"type:varchar(20);uniqueIndex;not null" json:"nopol"`
	Merk      string         `gorm:"type:varchar(50);not null" json:"merk"`
	Tipe      string         `gorm:"type:varchar(50)" json:"tipe"`
	Jenis     string         `gorm:"type:varchar(50);not null" json:"jenis"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}
