package routes

import (
	"otoscan-api/handlers"
	"otoscan-api/middleware"

	"github.com/gofiber/fiber/v2"
)

// SetupRoutes registers all application routes with JWT & Role-Based Access Control (RBAC)
func SetupRoutes(app *fiber.App) {
	// API Base Group
	api := app.Group("/api")

	// -------------------------------------------------------------
	// 1. Authentication Endpoints (/api/auth) - Public & Self Profile
	// -------------------------------------------------------------
	auth := api.Group("/auth")
	auth.Post("/register", handlers.Register)
	auth.Post("/login", handlers.Login)
	auth.Post("/logout", handlers.Logout)
	auth.Get("/me", middleware.Protected(), handlers.GetProfile)
	auth.Put("/me", middleware.Protected(), handlers.UpdateProfile)

	// -------------------------------------------------------------
	// 2. Master Data Endpoints (/api/master)
	// -------------------------------------------------------------
	master := api.Group("/master", middleware.Protected())

	// Read Master Data (Allowed for both 'user' and 'admin')
	master.Get("/damage-types", handlers.GetDamageTypes)
	master.Get("/angle-captures", handlers.GetAngleCaptures)
	master.Get("/inspection-statuses", handlers.GetInspectionStatuses)

	// Modify Master Data (Admin Only)
	masterAdmin := master.Group("", middleware.RequireRole("admin"))
	masterAdmin.Post("/damage-types", handlers.CreateDamageType)
	masterAdmin.Put("/damage-types/:id", handlers.UpdateDamageType)
	masterAdmin.Delete("/damage-types/:id", handlers.DeleteDamageType)

	masterAdmin.Post("/angle-captures", handlers.CreateAngleCapture)
	masterAdmin.Put("/angle-captures/:id", handlers.UpdateAngleCapture)
	masterAdmin.Delete("/angle-captures/:id", handlers.DeleteAngleCapture)

	masterAdmin.Post("/inspection-statuses", handlers.CreateInspectionStatus)
	masterAdmin.Put("/inspection-statuses/:id", handlers.UpdateInspectionStatus)
	masterAdmin.Delete("/inspection-statuses/:id", handlers.DeleteInspectionStatus)

	// -------------------------------------------------------------
	// 3. User Management Endpoints (/api/users) - Admin Only
	// -------------------------------------------------------------
	users := api.Group("/users", middleware.Protected(), middleware.RequireRole("admin"))
	users.Get("/", handlers.GetUsers)
	users.Get("/:id", handlers.GetUserByID)
	users.Post("/", handlers.CreateUser)
	users.Put("/:id", handlers.UpdateUser)
	users.Delete("/:id", handlers.DeleteUser)

	// -------------------------------------------------------------
	// 4. Employee Management Endpoints (/api/employees) - Admin Only
	// -------------------------------------------------------------
	employees := api.Group("/employees", middleware.Protected(), middleware.RequireRole("admin"))
	employees.Get("/", handlers.GetEmployees)
	employees.Get("/:id", handlers.GetEmployeeByID)
	employees.Post("/", handlers.CreateEmployee)
	employees.Put("/:id", handlers.UpdateEmployee)
	employees.Delete("/:id", handlers.DeleteEmployee)

	// -------------------------------------------------------------
	// 5. Vehicles Endpoints (/api/vehicles)
	// -------------------------------------------------------------
	vehicles := api.Group("/vehicles", middleware.Protected())
	vehicles.Get("/", handlers.GetVehicles)
	vehicles.Get("/:id", handlers.GetVehicleByID)
	vehicles.Post("/", handlers.CreateVehicle)
	vehicles.Put("/:id", handlers.UpdateVehicle)
	vehicles.Delete("/:id", middleware.RequireRole("admin"), handlers.DeleteVehicle)

	// -------------------------------------------------------------
	// 6. Inspections & AI YOLOv12 Endpoints (/api/inspections)
	// -------------------------------------------------------------
	inspections := api.Group("/inspections", middleware.Protected())

	// Read Inspections (Allowed for both 'user' and 'admin' — non-admin scoped to owned vehicles)
	inspections.Get("/", handlers.GetInspections)
	inspections.Get("/:id", handlers.GetInspectionByID)

	// Admin / Inspector Only Endpoints (Create, Edit, Delete, AI Scanning, Damage Items)
	inspectionsAdmin := inspections.Group("", middleware.RequireRole("admin"))
	inspectionsAdmin.Post("/", handlers.CreateInspection)
	inspectionsAdmin.Put("/:id", handlers.UpdateInspection)
	inspectionsAdmin.Delete("/:id", handlers.DeleteInspection)
	inspectionsAdmin.Post("/:id/damages", handlers.AddDamageItem)
	inspectionsAdmin.Delete("/:id/damages/:damageId", handlers.DeleteDamageItem)
	inspectionsAdmin.Post("/:id/detect", handlers.DetectDamageYOLOv12)
	inspectionsAdmin.Post("/detect-preview", handlers.DetectDamagePreview)
}
