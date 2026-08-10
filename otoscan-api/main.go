package main

import (
	"log"
	"os"

	"otoscan-api/config"
	"otoscan-api/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env if present
	_ = godotenv.Load()

	// Inisialisasi Koneksi PostgreSQL Database & AutoMigrate
	config.ConnectDatabase()

	// Inisialisasi Aplikasi Fiber
	app := fiber.New(fiber.Config{
		AppName: "OtoScan AI Backend API v1.0",
	})

	// Pastikan folder penyimpanan upload foto dan hasil AI ada
	_ = os.MkdirAll("./uploads/inspections", os.ModePerm)
	_ = os.MkdirAll("./uploads/results", os.ModePerm)

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))

	// Middleware CORS khusus untuk static uploads (Flutter Web CORS Fix)
	app.Use("/uploads", func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
		return c.Next()
	})
	app.Use("/api/uploads", func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
		return c.Next()
	})

	// Serve static files untuk gambar yang diunggah
	app.Static("/uploads", "./uploads")
	app.Static("/api/uploads", "./uploads")

	// Health Check / Ping Endpoint
	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"message":  "Halo! Server Golang Fiber & PostgreSQL OtoScan API 🚀",
			"status":   "success",
			"database": "PostgreSQL Ready",
		})
	})

	// Setup Dedicated Modular Routing Package
	routes.SetupRoutes(app)

	// Port Configuration
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server Otoscan API berjalan di http://localhost:%s", port)
	log.Fatal(app.Listen(":" + port))
}