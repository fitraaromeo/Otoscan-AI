package config

import (
	"fmt"
	"log"
	"os"
	"time"

	"otoscan-api/models"

	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// ConnectDatabase initializes PostgreSQL connection, runs AutoMigrate, and seeds master data
func ConnectDatabase() *gorm.DB {
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}

	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}

	user := os.Getenv("DB_USER")
	if user == "" {
		user = "postgres"
	}

	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "postgres"
	}

	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "otoscan_db"
	}

	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable"
	}

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Jakarta",
		host, user, password, dbname, port, sslmode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		log.Printf("⚠️ Gagal terhubung ke PostgreSQL: %v (Aplikasi berjalan tanpa database)", err)
		return nil
	}

	log.Println("✅ Berhasil terhubung ke database PostgreSQL!")

	// Auto-migrate tables (migrasi masing-masing model agar pembuatan tabel terjamin)
	modelsToMigrate := []interface{}{
		&models.DamageType{},
		&models.User{},
		&models.Vehicle{},
		&models.Employee{},
		&models.Inspection{},
		&models.AngleCapture{},
		&models.InspectionPhoto{},
		&models.DamageItem{},
	}

	for _, m := range modelsToMigrate {
		if err := db.AutoMigrate(m); err != nil {
			log.Printf("⚠️ AutoMigrate warning (%T): %v", m, err)
		}
	}

	// Eksekusi SQL DDL langsung untuk memastikan tabel inspection_photos dan kolom damage_items dibuat di PostgreSQL
	rawSQLMigration := `
		CREATE TABLE IF NOT EXISTS inspection_photos (
			id VARCHAR(36) PRIMARY KEY,
			inspection_id VARCHAR(36) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
			angle_capture_id VARCHAR(36) NOT NULL REFERENCES angle_captures(id) ON DELETE CASCADE,
			image_path TEXT NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			deleted_at TIMESTAMP WITH TIME ZONE
		);
		CREATE TABLE IF NOT EXISTS damage_items (
			id VARCHAR(36) PRIMARY KEY,
			inspection_photo_id VARCHAR(36) NOT NULL REFERENCES inspection_photos(id) ON DELETE CASCADE,
			damage_type_id VARCHAR(36) NOT NULL REFERENCES damage_types(id) ON DELETE CASCADE,
			quantity INT DEFAULT 1,
			bbox_coordinates TEXT,
			annotated_image_path TEXT,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			deleted_at TIMESTAMP WITH TIME ZONE
		);
		ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS inspection_photo_id VARCHAR(36);
		ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS bbox_coordinates TEXT;
		ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS annotated_image_path TEXT;
		ALTER TABLE damage_items DROP COLUMN IF EXISTS inspection_id CASCADE;
		ALTER TABLE damage_items DROP COLUMN IF EXISTS angle_capture_id CASCADE;
		ALTER TABLE employees ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
		CREATE INDEX IF NOT EXISTS idx_inspection_photos_inspection ON inspection_photos(inspection_id);
		CREATE INDEX IF NOT EXISTS idx_inspection_photos_angle_capture ON inspection_photos(angle_capture_id);
		CREATE INDEX IF NOT EXISTS idx_damage_items_inspection_photo ON damage_items(inspection_photo_id);
		CREATE INDEX IF NOT EXISTS idx_damage_items_damage_type ON damage_items(damage_type_id);
	`
	if err := db.Exec(rawSQLMigration).Error; err != nil {
		log.Printf("⚠️ Raw SQL migration error: %v", err)
	} else {
		log.Println("✅ Tabel inspection_photos, damage_items & relasi PostgreSQL berhasil dipastikan!")
	}

	// Seed Master Data
	seedDamageTypes(db)
	seedMasterAngleCaptures(db)
	seedUsers(db)
	seedEmployees(db)

	DB = db
	return db
}

func seedDamageTypes(db *gorm.DB) {
	var count int64
	db.Model(&models.DamageType{}).Count(&count)
	if count == 0 {
		seeds := []models.DamageType{
			{ID: uuid.New().String(), Code: "dent", Name: "Penyok Bodi", DefaultSeverity: "sedang", Description: "Lekukan atau deformasi akibat benturan pada bodi kendaraan", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Code: "scratch", Name: "Baret / Goresan", DefaultSeverity: "ringan", Description: "Goresan halus atau dalam pada permukaan cat bodi", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Code: "crack", Name: "Retak Bodi / Panel", DefaultSeverity: "sedang", Description: "Retakan fisik pada bodi, bumper, atau komponen plastik", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Code: "glass_shatter", Name: "Kaca Retak / Pecah", DefaultSeverity: "berat", Description: "Kerusakan kaca depan, kaca belakang, atau jendela samping", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Code: "lamp_broken", Name: "Lampu Pecah / Retak", DefaultSeverity: "berat", Description: "Kerusakan mika atau rumah lampu depan, rem, atau kabut", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Code: "tire_flat", Name: "Ban Kempes / Rusak", DefaultSeverity: "sedang", Description: "Kerusakan fisik, robek, atau ban bocor/kempes", CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		for _, seed := range seeds {
			db.Create(&seed)
		}
		log.Println("🌱 Master Data 6 Jenis Kerusakan (Matching YOLOv12 CarDD) berhasil dimasukkan ke PostgreSQL!")
	}
}

func seedMasterAngleCaptures(db *gorm.DB) {
	var count int64
	db.Model(&models.AngleCapture{}).Count(&count)
	if count == 0 {
		seeds := []models.AngleCapture{
			{ID: uuid.New().String(), Name: "Tampak Depan", Description: "Pindai bumper, kap mesin, kaca depan & lampu utama", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Name: "Tampak Belakang", Description: "Pindai bagasi, bumper belakang & lampu rem", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Name: "Tampak Samping", Description: "Pindai pintu, spion, bodi samping & velg", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Name: "Tampak Atas", Description: "Pindai atap kendaraan & panoramic roof", CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		for _, seed := range seeds {
			db.Create(&seed)
		}
		log.Println("🌱 Master Data 4 Sudut Pemindaian (Angle Captures) berhasil dimasukkan ke PostgreSQL!")
	}
}

func seedUsers(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Count(&count)
	if count == 0 {
		seeds := []models.User{
			{ID: uuid.New().String(), Name: "Bambang Wijaya", Email: "bambang.w@gmail.com", Phone: "081211112222", Address: "Jl. Sudirman No. 45, Jakarta Selatan", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), Name: "Dewi Lestari", Email: "dewi.lestari@yahoo.com", Phone: "081333334444", Address: "Jl. Gatot Subroto No. 88, Jakarta Selatan", CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		for _, seed := range seeds {
			db.Create(&seed)
		}
		log.Println("🌱 Master Data Pelanggan / User (Pemilik Kendaraan) berhasil dimasukkan ke PostgreSQL!")
	}
}

func seedEmployees(db *gorm.DB) {
	var count int64
	db.Model(&models.Employee{}).Count(&count)
	if count == 0 {
		seeds := []models.Employee{
			{ID: uuid.New().String(), IDKependudukan: "3171012345670001", Name: "Budi Santoso", Email: "budi.santoso@otoscan.id", Phone: "081234567890", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), IDKependudukan: "3171012345670002", Name: "Siti Rahma", Email: "siti.rahma@otoscan.id", Phone: "081298765432", CreatedAt: time.Now(), UpdatedAt: time.Now()},
			{ID: uuid.New().String(), IDKependudukan: "3171012345670003", Name: "Ahmad Hidayat", Email: "ahmad.hidayat@otoscan.id", Phone: "081100001111", CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
		for _, seed := range seeds {
			db.Create(&seed)
		}
		log.Println("🌱 Master Data Karyawan (Employees) berhasil dimasukkan ke PostgreSQL!")
	}
}
