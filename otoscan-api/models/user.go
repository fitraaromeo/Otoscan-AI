package models

import (
	"time"

	"gorm.io/gorm"
)

// User represents a customer / vehicle owner entity
type User struct {
	ID           string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Name         string         `gorm:"type:varchar(100);not null" json:"name"`
	Email        string         `gorm:"type:varchar(100);unique" json:"email"`
	Phone        string         `gorm:"type:varchar(20)" json:"phone"`
	Address      string         `gorm:"type:text" json:"address"`
	VehicleCount int            `gorm:"-" json:"vehicleCount"`
	CreatedAt    time.Time      `json:"createdAt"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Vehicles []Vehicle `gorm:"foreignKey:UserID;constraint:OnDelete:SET NULL;" json:"vehicles,omitempty"`
}
