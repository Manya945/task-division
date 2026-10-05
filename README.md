# 🚛 SURAKSHA WIM — Smart Overload & ANPR Detection System

> **Automated Weigh-in-Motion (WIM), Automatic Number Plate Recognition (ANPR), and E-Challan Enforcement System for Indian National Highways & RTOs.**

---

## 👥 4 Members ka Work Division & Project Architecture

All 4 modules are organized in dedicated directories under one repository:

```text
smart_overload_system/
├── run_system.py                 # 🚀 One-Click Master Launcher (Runs DB, Backend & Web UI)
├── backend/                      # 👤 Member 2: FastAPI + SQLite + REST APIs + WebSockets
│   ├── app/
│   │   ├── main.py               # Central Brain & REST API Gateway
│   │   ├── database.py           # SQLite Schema (Users, Vehicles, Violations, Alerts, Locations)
│   │   ├── models.py             # Pydantic Schemas
│   │   ├── auth.py               # Token auth & password hashing
│   │   └── seed_data.py          # VAHAN vehicle registry & checkpoint seeding
│   ├── requirements.txt
│   └── run_backend.py
│
├── anpr_engine/                  # 👤 Member 3: AI/ANPR Engine (OpenCV + EasyOCR + Pattern Matching)
│   ├── anpr_processor.py         # License plate extraction, OCR rectification & Indian regex
│   ├── generate_samples.py       # High-Security Registration Plate (HSRP) graphic generator
│   ├── test_anpr.py              # Unit tests for OCR and regex normalization
│   └── sample_images/            # Pre-generated sample plates (CG10AB1234, MH12DE1433, etc.)
│
├── hardware_esp32/               # 👤 Member 4: Hardware Firmware + Simulation + Integration Testing
│   ├── esp32_weight_sensor.ino   # ESP32 C++ firmware (HX711 load cell + WiFi + buzzer/LED)
│   ├── wiring_diagram.md         # Circuit diagram & pinout specification
│   ├── simulate_hardware.py      # Python load cell simulator (Interactive & Traffic stream)
│   └── test_integration.py       # End-to-end regression & integration test suite
│
├── mobile_app_flutter/           # 👤 Member 1: Flutter + Dart Mobile App
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart             # App Entry & Dark RTO Theme
│       ├── models/               # Vehicle, Violation, Alert, WeightRecord
│       ├── services/
│       │   └── api_service.dart  # Full HTTP client connecting to FastAPI Backend
│       └── screens/              # All 10 Screens:
│           ├── splash_screen.dart
│           ├── login_screen.dart
│           ├── dashboard_screen.dart
│           ├── vehicle_scan_screen.dart
│           ├── weight_check_screen.dart
│           ├── violation_details_screen.dart
│           ├── violation_history_screen.dart
│           ├── alerts_screen.dart
│           ├── map_screen.dart
│           └── profile_screen.dart
│
└── web_dashboard/                # 🌐 Standalone Live Control Room Demo (HTML5 + CSS + WebSockets)
    ├── index.html                # Live presentation dashboard for judges & evaluation
    └── app.js                    # Real-time WebSocket event handler & actuator animations
```

---

## ⚡ Quick Start: Run Everything in 1 Command

Open a terminal in `smart_overload_system/` and run:

```bash
python run_system.py
```

This will automatically:
1. Initialize the SQLite database with Indian commercial trucks, checkpoints, and RTO officers.
2. Start the FastAPI backend server on `http://localhost:8000`.
3. Open the interactive **Live Control Room Dashboard** in your browser.
4. Interactive Swagger API Docs will be available at: `http://localhost:8000/docs`.

---

## 🔬 Testing the Complete 4-Member Pipeline

### 1. Test Member 4's Overload Scenario (CG10AB1234 — 14,500 kg vs 10,000 kg Limit)
In a second terminal, run:

```bash
cd hardware_esp32
python simulate_hardware.py
```

**Output:**
```text
[ESP32 SIMULATOR -> BACKEND] Transmitting reading:
  Vehicle: CG10AB1234 | Measured Weight: 14,500 kg
  [!] STATUS: >>> OVERLOAD DETECTED <<<
  [!] Permitted Limit: 10,000 kg
  [!] Excess Weight:   +4,500 kg
  [!] E-Challan No:    ECH-CG-2026-XXXXX
  [!] Penalty Fine:    Rs. 30,000
  [!] ESP32 Actuators: [BUZZER ON] [RED LED ON] [BARRIER LOCKED]
```
The web dashboard and mobile app will immediately update in real-time via WebSockets without needing a page refresh!

### 2. Stream Continuous Traffic for Hackathon Presentations
```bash
python simulate_hardware.py --stream
```

### 3. Run Automated Integration Tests
```bash
cd hardware_esp32
python test_integration.py
```

### 4. Run AI/ANPR Unit Tests (Member 3)
```bash
cd anpr_engine
python test_anpr.py
```

---

## ⚖️ Motor Vehicles (Amendment) Act Penalty Engine

The system strictly implements the statutory fine formula:
- **Base Fine:** ₹20,000 (Section 194 MV Act 2019)
- **Excess Weight Surcharge:** ₹2,000 per metric tonne (or part thereof) over permissible GVW.
- **Example Calculation:**
  $$\text{Measured} = 14,500\text{ kg}, \quad \text{Allowed} = 10,000\text{ kg}$$
  $$\text{Excess} = 4,500\text{ kg} \implies 5\text{ tonnes surcharge}$$
  $$\text{Fine} = 20,000 + (5 \times 2,000) = \mathbf{₹30,000}$$

---

## 🌿 GitHub Collaboration Strategy

Keep **one central repository** with four feature branches:

```text
main (Production / Merged)
├── frontend  (Member 1 -> mobile_app_flutter/)
├── backend   (Member 2 -> backend/)
├── anpr      (Member 3 -> anpr_engine/)
└── hardware  (Member 4 -> hardware_esp32/)
```

Member 2 acts as the **Integration Lead**, reviewing pull requests into `main`.
