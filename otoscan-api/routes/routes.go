package routes

import (
	"otoscan-api/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupRoutes registers all application routes cleanly on the Fiber app instance
func SetupRoutes(app *fiber.App) {
	// API Base Group
	api := app.Group("/api")

	// 1. Master Data Endpoints (/api/master)
	master := api.Group("/master")
	master.Get("/damage-types", handlers.GetDamageTypes)
	master.Post("/damage-types", handlers.CreateDamageType)
	master.Delete("/damage-types/:id", handlers.DeleteDamageType)

	master.Get("/angle-captures", handlers.GetAngleCaptures)
	master.Post("/angle-captures", handlers.CreateAngleCapture)
	master.Delete("/angle-captures/:id", handlers.DeleteAngleCapture)

	// 2. Users / Pemilik Kendaraan Endpoints (/api/users)
	users := api.Group("/users")
	users.Get("/", handlers.GetUsers)
	users.Get("/:id", handlers.GetUserByID)
	users.Post("/", handlers.CreateUser)
	users.Put("/:id", handlers.UpdateUser)
	users.Delete("/:id", handlers.DeleteUser)

	// 3. Vehicles / Master Kendaraan Endpoints (/api/vehicles)
	vehicles := api.Group("/vehicles")
	vehicles.Get("/", handlers.GetVehicles)
	vehicles.Get("/:id", handlers.GetVehicleByID)
	vehicles.Post("/", handlers.CreateVehicle)
	vehicles.Put("/:id", handlers.UpdateVehicle)
	vehicles.Delete("/:id", handlers.DeleteVehicle)

	// 4. Employees / Karyawan Endpoints (/api/employees)
	employees := api.Group("/employees")
	employees.Get("/", handlers.GetEmployees)
	employees.Get("/:id", handlers.GetEmployeeByID)
	employees.Post("/", handlers.CreateEmployee)
	employees.Put("/:id", handlers.UpdateEmployee)
	employees.Delete("/:id", handlers.DeleteEmployee)

	// 5. Inspections & AI YOLOv12 Endpoints (/api/inspections)
	inspections := api.Group("/inspections")
	inspections.Get("/", handlers.GetInspections)
	inspections.Get("/:id", handlers.GetInspectionByID)
	inspections.Post("/", handlers.CreateInspection)
	inspections.Delete("/:id", handlers.DeleteInspection)
	inspections.Post("/:id/damages", handlers.AddDamageItem)
	inspections.Delete("/:id/damages/:damageId", handlers.DeleteDamageItem)
	inspections.Post("/:id/detect", handlers.DetectDamageYOLOv12)
}
