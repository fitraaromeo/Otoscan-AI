package models

import (
	"time"

	"gorm.io/gorm"
)

// Inspection represents a vehicle inspection record
type Inspection struct {
	ID         string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	VehicleID  string         `gorm:"type:varchar(36);not null;index" json:"vehicleId"`
	EmployeeID *string        `gorm:"type:varchar(36);index" json:"employeeId"`
	Status     string         `gorm:"type:varchar(30);default:'inProgress'" json:"status"` // draft, inProgress, completed
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Vehicle  *Vehicle          `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	Employee *Employee         `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	Photos   []InspectionPhoto `gorm:"foreignKey:InspectionID;constraint:OnDelete:CASCADE;" json:"photos,omitempty"`
}
