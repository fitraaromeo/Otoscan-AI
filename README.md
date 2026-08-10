<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" />
<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
<img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
<img src="https://img.shields.io/badge/YOLOv12-FF0000?style=for-the-badge&logo=opencv&logoColor=white" />

# 🚗 OtoScan AI — Intelligent Vehicle Inspection System

**OtoScan AI** adalah sistem inspeksi fisik kendaraan berbasis kecerdasan buatan yang mendeteksi kerusakan otomatis menggunakan **YOLOv12 Computer Vision**. Sistem dirancang sebagai **Monorepo** dengan 3 microservice yang terintegrasi secara penuh.

[🔗 Live Demo](#) · [🐛 Report Bug](https://github.com/fitraaromeo/Otoscan-AI/issues) · [💡 Request Feature](https://github.com/fitraaromeo/Otoscan-AI/issues)

</div>

---

## 📸 Screenshots

<div align="center">

| Dashboard | 4-Side Scanner | Inspection Detail |
| :---: | :---: | :---: |
| <img src="screenshots/dashboard.png" width="220"/> | <img src="screenshots/4 side scanner.png" width="220"/> | <img src="screenshots/inspection detail.png" width="220"/> |
| Daftar kendaraan & statistik inspeksi | Scanner 4 sisi kendaraan + AI detection | Laporan kerusakan & annotated bounding box |

</div>


---

## 🏗️ Arsitektur Sistem

```
Otoscan-AI (Monorepo)
│
├── 📱  otoscan_app/       — Flutter Frontend (Web · Android · iOS)
│       └── Provider · REST API · Real-time AI Scan Canvas
│
├── ⚡  otoscan-api/       — Go Fiber REST API + PostgreSQL
│       └── GORM · JWT Auth · Static File Server · CORS
│
└── 🧠  ai-service/        — Python FastAPI AI Microservice
        └── YOLOv12 · OpenCV · Bounding Box Annotation
```

### 🔄 Alur Data

```mermaid
flowchart LR
    A([📱 Flutter App]) -- POST /upload-and-detect --> B([⚡ Go Fiber API])
    B -- POST /detect --> C([🧠 Python AI])
    C --> D([🔍 YOLOv12 Inference])
    D --> E([🖼️ Annotated Image + JSON Result])
    E --> F([💾 PostgreSQL + Disk])
    F -- JSON Response --> A

    style A fill:#02569B,color:#fff,stroke:#0288D1
    style B fill:#00ADD8,color:#fff,stroke:#00838F
    style C fill:#3776AB,color:#fff,stroke:#1a5276
    style D fill:#FF6B35,color:#fff,stroke:#E55B2B
    style E fill:#6C3483,color:#fff,stroke:#5B2C6F
    style F fill:#316192,color:#fff,stroke:#1a4f7a
```

---

## 🧠 AI — Damage Detection

Model **YOLOv12** dilatih dengan dataset **CarDD (Car Damage Detection)** untuk mendeteksi 6 jenis kerusakan:

| Kode            | Jenis Kerusakan  | Ikon |
| --------------- | ---------------- | ---- |
| `dent`          | Penyok / Lekukan | 🔵   |
| `scratch`       | Goresan / Lecet  | 🟡   |
| `crack`         | Retak / Pecah    | 🔴   |
| `glass_shatter` | Kaca Pecah       | 🟣   |
| `lamp_broken`   | Lampu Rusak      | 🟠   |
| `tire_flat`     | Ban Kempes       | ⚪   |

---

## 🛠️ Tech Stack

### 📱 Frontend — `otoscan_app/`

- **Framework**: Flutter 3.x (Multi-Platform)
- **State Management**: Provider
- **Features**:
  - Inspeksi visual 4-sisi kendaraan (Depan · Belakang · Samping · Atas)
  - Tampilan annotated bounding box hasil AI dari backend
  - Light / Dark Mode dinamis
  - Manajemen data kendaraan, karyawan, dan history inspeksi

### ⚡ Backend API — `otoscan-api/`

- **Language**: Go (Golang) v1.21+
- **Framework**: Fiber v2
- **Database**: PostgreSQL + GORM ORM
- **Features**:
  - Auto Migration & Database Seeding
  - Static file server dengan CORS (`/uploads/inspections/`, `/uploads/results/`)
  - REST Endpoints: Kendaraan, Karyawan, Inspeksi, AI Detection
  - Cascading delete inspeksi

### 🧠 AI Microservice — `ai-service/`

- **Language**: Python 3.10+
- **Framework**: FastAPI + Uvicorn
- **Model**: YOLOv12 (CarDD Dataset)
- **Libraries**: Ultralytics, OpenCV, Pillow
- **Output**: Annotated JPEG + JSON koordinat bounding box

---

## 🚀 Quick Start

### Prerequisites

| Tool        | Minimum Version |
| ----------- | --------------- |
| Flutter SDK | 3.x             |
| Go          | 1.21+           |
| Python      | 3.10+           |
| PostgreSQL  | 14+             |

### 📥 Clone Repository

```bash
git clone https://github.com/fitraaromeo/Otoscan-AI.git
cd Otoscan-AI
```

---

### Step 1 — 🧠 Jalankan AI Microservice (Port: 8000)

```bash
cd ai-service
pip install -r requirements.txt
python main.py
```

> ✅ AI berjalan di `http://127.0.0.1:8000`

---

### Step 2 — ⚡ Jalankan Go Fiber API Backend (Port: 8080)

Buat file `.env` di dalam folder `otoscan-api/`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_NAME=otoscan_db
AI_SERVICE_URL=http://localhost:8000
```

Kemudian jalankan:

```bash
cd otoscan-api
go run main.go
```

> ✅ API berjalan di `http://localhost:8080`  
> ✅ Static uploads tersedia di `http://localhost:8080/uploads/`

---

### Step 3 — 📱 Jalankan Flutter App

```bash
cd otoscan_app
flutter pub get
flutter run -d chrome
```

> ✅ App Flutter terbuka di browser / perangkat

---

## 📂 Struktur Project

```
Otoscan-AI/
│
├── 📱 otoscan_app/
│   ├── lib/
│   │   ├── models/         # Data Models (VehicleRecord, AngleCapture, DamageItem)
│   │   ├── screens/        # UI Screens (Dashboard, Scanner, Detail, Login)
│   │   ├── services/       # API Service (HTTP Client)
│   │   ├── state/          # App State (Provider)
│   │   ├── theme/          # App Theme & Colors
│   │   └── widgets/        # Reusable Widgets
│   └── pubspec.yaml
│
├── ⚡ otoscan-api/
│   ├── config/             # Database Config
│   ├── handlers/           # HTTP Handlers (inspection, ai, employee, vehicle)
│   ├── middleware/         # Auth Middleware
│   ├── models/             # GORM Models
│   ├── routes/             # API Routes
│   ├── uploads/            # Uploaded & Result Images
│   │   ├── inspections/    # Raw uploaded photos
│   │   └── results/        # AI-annotated result images
│   └── main.go
│
├── 🧠 ai-service/
│   ├── main.py             # FastAPI entry point
│   ├── requirements.txt
│   └── yolov12/            # YOLOv12 model & utilities
│
├── 🐳 docker-compose.yml   # Docker orchestration (optional)
└── 📄 README.md
```

---

## 📡 API Endpoints

| Method   | Endpoint                                 | Deskripsi                         |
| -------- | ---------------------------------------- | --------------------------------- |
| `POST`   | `/api/auth/login`                        | Login pengguna                    |
| `GET`    | `/api/vehicles`                          | Daftar semua kendaraan            |
| `GET`    | `/api/employees`                         | Daftar semua karyawan             |
| `GET`    | `/api/inspections`                       | Daftar semua inspeksi             |
| `POST`   | `/api/inspections`                       | Buat inspeksi baru                |
| `POST`   | `/api/inspections/:id/upload-and-detect` | Upload foto + jalankan AI YOLOv12 |
| `DELETE` | `/api/inspections/:id`                   | Hapus data inspeksi               |

---

## 🐳 Docker (Opsional)

```bash
docker-compose up -d
```

---

## 👤 Author

**Fitra Romeo Winky**

[![GitHub](https://img.shields.io/badge/GitHub-fitraaromeo-181717?style=flat&logo=github&logoColor=white)](https://github.com/fitraaromeo)
[![Instagram](https://img.shields.io/badge/Instagram-fitraaromeo-E4405F?style=flat&logo=instagram&logoColor=white)](https://www.instagram.com/fitraaromeo)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Fitra%20Winky-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/fitra-winky-380836266/)
[![Portfolio](https://img.shields.io/badge/Portfolio-Vercel-000000?style=flat&logo=vercel&logoColor=white)](https://portfolio-fitra-romeo-winky.vercel.app/)

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<div align="center">
  Made with ❤️ using Flutter · Go Fiber · Python FastAPI · YOLOv12
</div>
