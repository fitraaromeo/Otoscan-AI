-- Schema SQL untuk OtoScan AI Vehicle Inspection System
-- Database: PostgreSQL 16+

-- Enable Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table 1: Master Damage Types (Master Data Jenis Kerusakan - 6 Kelas YOLOv12 CarDD)
CREATE TABLE IF NOT EXISTS damage_types (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    code VARCHAR(50) NOT NULL UNIQUE, -- e.g. dent, scratch, crack, glass_shatter, lamp_broken, tire_flat
    name VARCHAR(100) NOT NULL,
    default_severity VARCHAR(20) NOT NULL DEFAULT 'ringan', -- ringan, sedang, berat
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 2: Master Inspection Statuses (Master Data Status Inspeksi Kendaraan)
CREATE TABLE IF NOT EXISTS inspection_statuses (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    code VARCHAR(50) NOT NULL UNIQUE, -- waiting, inProgress, completed, failed
    name VARCHAR(100) NOT NULL, -- Menunggu Antrean, In Progress, Selesai, Gagal
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 3: Users (Master Data Pemilik Kendaraan / Pelanggan)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 4: Vehicles (Master Data Kendaraan)
CREATE TABLE IF NOT EXISTS vehicles (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
    nopol VARCHAR(20) NOT NULL UNIQUE,
    merk VARCHAR(50) NOT NULL,
    tipe VARCHAR(50) NOT NULL DEFAULT '',
    jenis VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 5: Employees (Master Data Karyawan / Inspektur)
CREATE TABLE IF NOT EXISTS employees (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    id_kependudukan VARCHAR(30) NOT NULL UNIQUE, -- No. KTP / NIK Kependudukan
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 6: Inspections (Transaksi Utama Inspeksi Kendaraan)
CREATE TABLE IF NOT EXISTS inspections (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    vehicle_id VARCHAR(36) NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    employee_id VARCHAR(36) REFERENCES employees(id) ON DELETE SET NULL,
    status_id VARCHAR(36) REFERENCES inspection_statuses(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 7: Master Angle Captures (Master Data Sudut Pemindaian Standar)
CREATE TABLE IF NOT EXISTS angle_captures (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name VARCHAR(100) NOT NULL UNIQUE, -- Tampak Depan, Tampak Belakang, Tampak Samping, Tampak Atas
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 8: Inspection Photos (Penyimpanan Path / URL Foto Per Sudut Inspeksi)
CREATE TABLE IF NOT EXISTS inspection_photos (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    inspection_id VARCHAR(36) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    angle_capture_id VARCHAR(36) NOT NULL REFERENCES angle_captures(id) ON DELETE CASCADE,
    image_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Table 9: Damage Items (Hasil Inferensi YOLOv12 Per Foto Inspeksi)
CREATE TABLE IF NOT EXISTS damage_items (
    id VARCHAR(36) PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    inspection_photo_id VARCHAR(36) NOT NULL REFERENCES inspection_photos(id) ON DELETE CASCADE,
    damage_type_id VARCHAR(36) NOT NULL REFERENCES damage_types(id) ON DELETE CASCADE,
    quantity INT DEFAULT 1,
    bbox_coordinates TEXT,
    annotated_image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Auto-Add & Ensure deleted_at columns on ALL tables in PostgreSQL
ALTER TABLE damage_types ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE damage_types ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE damage_types ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE inspection_statuses ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspection_statuses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspection_statuses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tipe VARCHAR(50) DEFAULT '';
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE employees ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE inspections ADD COLUMN IF NOT EXISTS status_id VARCHAR(36);
ALTER TABLE inspections DROP COLUMN IF EXISTS status CASCADE;
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_inspections_status'
    ) THEN 
        ALTER TABLE inspections 
        ADD CONSTRAINT fk_inspections_status 
        FOREIGN KEY (status_id) 
        REFERENCES inspection_statuses(id) 
        ON DELETE SET NULL;
    END IF; 
END $$;
ALTER TABLE inspections ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspections ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspections ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE angle_captures ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE angle_captures ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE angle_captures ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE inspection_photos ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspection_photos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inspection_photos ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS bbox_coordinates TEXT;
ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS annotated_image_path TEXT;
ALTER TABLE damage_items DROP COLUMN IF EXISTS inspection_id CASCADE;
ALTER TABLE damage_items DROP COLUMN IF EXISTS angle_capture_id CASCADE;
ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE damage_items ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Indexing untuk query cepat
CREATE INDEX IF NOT EXISTS idx_damage_types_code ON damage_types(code);
CREATE INDEX IF NOT EXISTS idx_inspection_statuses_code ON inspection_statuses(code);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_vehicles_user ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_id_kependudukan ON employees(id_kependudukan);
CREATE INDEX IF NOT EXISTS idx_inspections_vehicle ON inspections(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_inspections_status_id ON inspections(status_id);
CREATE INDEX IF NOT EXISTS idx_inspection_photos_inspection ON inspection_photos(inspection_id);
CREATE INDEX IF NOT EXISTS idx_inspection_photos_angle_capture ON inspection_photos(angle_capture_id);
CREATE INDEX IF NOT EXISTS idx_damage_items_inspection_photo ON damage_items(inspection_photo_id);
CREATE INDEX IF NOT EXISTS idx_damage_items_damage_type ON damage_items(damage_type_id);

-- Master Seed Data: Exactly 6 Classes Matching YOLOv12 CarDD Model
INSERT INTO damage_types (code, name, default_severity, description)
VALUES 
    ('dent', 'Penyok Bodi', 'sedang', 'Lekukan atau deformasi akibat benturan pada bodi kendaraan'),
    ('scratch', 'Baret / Goresan', 'ringan', 'Goresan halus atau dalam pada permukaan cat bodi'),
    ('crack', 'Retak Bodi / Panel', 'sedang', 'Retakan fisik pada bodi, bumper, atau komponen plastik'),
    ('glass_shatter', 'Kaca Retak / Pecah', 'berat', 'Kerusakan kaca depan, kaca belakang, atau jendela samping'),
    ('lamp_broken', 'Lampu Pecah / Retak', 'berat', 'Kerusakan mika atau rumah lampu depan, rem, atau kabut'),
    ('tire_flat', 'Ban Kempes / Rusak', 'sedang', 'Kerusakan fisik, robek, atau ban bocor/kempes')
ON CONFLICT (code) DO NOTHING;

-- Master Seed Data: 4 Inspection Statuses
INSERT INTO inspection_statuses (code, name, description)
VALUES 
    ('waiting', 'Menunggu Antrean', 'Inspeksi dalam antrean menunggu giliran pemindaian'),
    ('inProgress', 'In Progress', 'Inspeksi kendaraan sedang berlangsung'),
    ('completed', 'Selesai', 'Inspeksi kendaraan telah selesai dilakukan'),
    ('failed', 'Gagal', 'Inspeksi kendaraan gagal atau dibatalkan')
ON CONFLICT (code) DO NOTHING;

-- Master Seed Data: Standard 4 Angle Captures
INSERT INTO angle_captures (name, description)
VALUES
    ('Tampak Depan', 'Pindai bumper, kap mesin, kaca depan & lampu utama'),
    ('Tampak Belakang', 'Pindai bagasi, bumper belakang & lampu rem'),
    ('Tampak Samping', 'Pindai pintu, spion, bodi samping & velg'),
    ('Tampak Atas', 'Pindai atap kendaraan & panoramic roof')
ON CONFLICT (name) DO NOTHING;

-- Master Seed Data: Users (Pemilik Kendaraan)
INSERT INTO users (name, email, phone, address)
VALUES 
    ('Bambang Wijaya', 'bambang.w@gmail.com', '081211112222', 'Jl. Sudirman No. 45, Jakarta Selatan'),
    ('Dewi Lestari', 'dewi.lestari@yahoo.com', '081333334444', 'Jl. Gatot Subroto No. 88, Jakarta Selatan')
ON CONFLICT (email) DO NOTHING;

-- Master Seed Data: Employees
INSERT INTO employees (id_kependudukan, name, email, phone)
VALUES 
    ('3171012345670001', 'Budi Santoso', 'budi.santoso@otoscan.id', '081234567890'),
    ('3171012345670002', 'Siti Rahma', 'siti.rahma@otoscan.id', '081298765432'),
    ('3171012345670003', 'Ahmad Hidayat', 'ahmad.hidayat@otoscan.id', '081100001111')
ON CONFLICT (id_kependudukan) DO NOTHING;
