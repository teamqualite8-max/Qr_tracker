# QR Part Tracker — Industrial Control Stages App

A Flutter mobile application for tracking industrial parts through two QR-code-based control stages. Works fully **offline** on Android phones and tablets.

---

## Features

| Feature | Details |
|---|---|
| **QR Scanning** | Camera-based QR code scanning via `mobile_scanner` |
| **Post 1 Control** | Scan → Auto-timestamp → Capture photo → Save to SQLite |
| **Post 2 Control** | Validates Post 1 is done → Capture photo → Mark fully complete |
| **Verify** | Scan any part to view full status, timestamps, and photos |
| **Dashboard** | Stats overview, visual progress bar, searchable/filterable parts list |
| **CSV Import** | File picker to import Part IDs from CSV (from Excel) |
| **Offline** | 100% local — SQLite + local image storage, no internet required |
| **Delay Tracking** | Automatically computes time between Post 1 and Post 2 |
| **Color Coding** | 🔴 Not Processed / 🟡 Post 1 Done / 🟢 Fully Complete |

---

## Project Structure

```
lib/
├── main.dart                    # App entry + bottom navigation shell
├── theme.dart                   # Colors, ThemeData
├── models/
│   └── part.dart                # Part model + PartStatus enum
├── services/
│   ├── database_service.dart    # SQLite CRUD operations
│   └── csv_service.dart         # CSV file import logic
├── screens/
│   ├── scan_screen.dart         # QR scanner + Post 1 / Post 2 logic
│   ├── verify_screen.dart       # QR scan → part status detail view
│   ├── dashboard_screen.dart    # Stats, progress bar, parts list
│   └── camera_capture_screen.dart  # Full-screen camera for photos
└── widgets/
    └── status_badge.dart        # Colored status pill widget

assets/
└── sample_parts.csv             # Example CSV for testing import
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 21+, physical device recommended for camera)

### 1. Clone / Download the project
```bash
# Place all files in a folder called qr_tracker/
cd qr_tracker
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run on Android device (USB debugging enabled)
```bash
flutter run
```

### 4. Build a release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 5. Install APK on device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## CSV File Format

The app accepts CSV files exported from Excel. Supported formats:

**Format 1 — Header row (recommended):**
```csv
part_id
BEV-0001
BEV-0002
ENG-0001
```

**Format 2 — No header (single column):**
```csv
BEV-0001
BEV-0002
ENG-0001
```

**Format 3 — Multi-column with header:**
```csv
part_id,description,category
BEV-0001,Beverage Valve,Fluid
ENG-0002,Engine Mount,Mechanical
```

The app auto-detects the column containing Part IDs.  
A sample CSV is included at `assets/sample_parts.csv`.

---

## How to Use

### Step 1 — Import Parts
1. Open the **Dashboard** tab
2. Tap the **↑ Upload** icon in the top right
3. Select your CSV file from device storage
4. Parts are imported and ready to scan

### Step 2 — Post 1 Scanning
1. Go to the **Scan** tab
2. Select **POST 1** mode (yellow)
3. Scan the QR code on the part
4. Camera opens automatically — take the photo
5. Status updates to `POST1_DONE`

### Step 3 — Post 2 Scanning
1. Select **POST 2** mode (green) in the Scan tab
2. Scan the QR code
3. If Post 1 not done → warning shown, no action taken
4. If Post 1 done → camera opens, take photo, status → `POST2_DONE`

### Step 4 — Verify a Part
1. Go to the **Verify** tab
2. Scan any QR code
3. See full status, timestamps, photos, and delay between stages

---

## Database Schema

```sql
CREATE TABLE parts (
  part_id         TEXT PRIMARY KEY,
  status          TEXT NOT NULL DEFAULT 'NOT_PROCESSED',
  post1_timestamp TEXT,
  post1_image_path TEXT,
  post2_timestamp TEXT,
  post2_image_path TEXT
);
```

Images are stored in: `{AppDocumentsDir}/part_images/`  
Only the file path is stored in the database.

---

## Status Values

| Status | Color | Meaning |
|---|---|---|
| `NOT PROCESSED` | 🔴 Red | Part not yet scanned at any post |
| `POST1_DONE` | 🟡 Yellow | Passed Control Stage 1 |
| `POST2_DONE` | 🟢 Green | Fully completed both stages |

---

## Android Permissions Required

| Permission | Purpose |
|---|---|
| `CAMERA` | QR scanning + photo capture |
| `READ_EXTERNAL_STORAGE` | CSV file import (Android ≤ 12) |
| `READ_MEDIA_IMAGES` | CSV file import (Android 13+) |

---

## Key Packages Used

| Package | Purpose |
|---|---|
| `mobile_scanner` | Camera-based QR scanning |
| `camera` | Photo capture at control posts |
| `sqflite` | Local SQLite database |
| `file_picker` | CSV file selection |
| `csv` | CSV parsing |
| `path_provider` | App storage paths |
| `permission_handler` | Runtime permissions |
| `intl` | Timestamp formatting |

---

## Optional Enhancements (Next Steps)

- **Export to Excel/CSV** — Generate a report of all parts with timestamps
- **Operator Login** — Track which operator processed each part
- **Bluetooth Scanner** — Pair with handheld Bluetooth QR scanners
- **Part Notes** — Add freetext notes at each stage
- **Multi-language** — Arabic / French for North African industrial sites
