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
	StatusID   *string        `gorm:"type:varchar(36);index" json:"statusId"`
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Vehicle          *Vehicle          `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	Employee         *Employee         `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	InspectionStatus *InspectionStatus `gorm:"foreignKey:StatusID;constraint:OnDelete:SET NULL;" json:"inspectionStatus,omitempty"`
	Photos           []InspectionPhoto `gorm:"foreignKey:InspectionID;constraint:OnDelete:CASCADE;" json:"photos,omitempty"`
}
