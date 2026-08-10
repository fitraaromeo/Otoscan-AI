package models

import (
	"time"

	"gorm.io/gorm"
)

// Employee represents company employee / inspector entity
type Employee struct {
	ID             string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	IDKependudukan string         `gorm:"type:varchar(30);uniqueIndex;column:id_kependudukan;not null" json:"idKependudukan"`
	Name           string         `gorm:"type:varchar(100);not null" json:"name"`
	Email          string         `gorm:"type:varchar(100);unique" json:"email"`
	Phone          string         `gorm:"type:varchar(20)" json:"phone"`
	IsActive       bool           `gorm:"type:boolean;default:true;column:is_active" json:"isActive"`
	CreatedAt      time.Time      `json:"createdAt"`
	UpdatedAt      time.Time      `json:"updatedAt"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}
