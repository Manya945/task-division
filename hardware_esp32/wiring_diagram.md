# 🔌 Hardware Wiring & Pin Configuration Guide

## 👤 Member 4: Hardware + Integration + Testing

This document details the circuit schematic and wiring connections for the **ESP32 Microcontroller**, **HX711 24-bit ADC Amplifier**, **Strain Gauge Load Cell**, and alert indicators.

---

## 📋 Bill of Materials (BOM)

| Component | Specification | Purpose |
| :--- | :--- | :--- |
| **Microcontroller** | ESP32-WROOM-32 (NodeMCU / DevKit) | Central controller, WiFi REST API client |
| **ADC Amplifier** | HX711 24-bit Precision ADC Module | Converts microvolt signals from load cell |
| **Weight Sensor** | 4-Wire Wheatstone Bridge Load Cell (50kg/500kg/5T) | Measures vehicle load |
| **Overload LED** | 5mm High-Intensity Red LED | Immediate visual warning for overloaded vehicles |
| **Pass LED** | 5mm High-Intensity Green LED | Visual indicator for permissible weight |
| **Buzzer** | 5V Active Piezo Buzzer | Audible alarm at toll booth |
| **Relay / Servo** | 5V Single-Channel Relay / SG90 Servo | Controls toll barrier gate |
| **Power Supply** | 5V 2A DC Adapter / USB-C | Powers ESP32 and peripheral sensors |

---

## 🛠️ Pin Connection Table

### 1. ESP32 to HX711 Module
| ESP32 Pin | HX711 Pin | Description |
| :--- | :--- | :--- |
| **GPIO 21** | `DT` (Data) | Serial Data Output from ADC |
| **GPIO 22** | `SCK` (Clock) | Clock input to ADC |
| **5V (VIN)** | `VCC` | Power supply (5V or 3.3V) |
| **GND** | `GND` | Ground reference |

### 2. HX711 to 4-Wire Load Cell
| HX711 Terminal | Load Cell Wire Color | Function |
| :--- | :--- | :--- |
| `E+` | **Red** | Excitation Positive (Power) |
| `E-` | **Black** | Excitation Negative (Ground) |
| `A+` | **Green** | Signal / Output Positive |
| `A-` | **White** | Signal / Output Negative |

*(Note: If reading is negative when weight is applied, swap Green and White wires or negate calibration factor).*

### 3. ESP32 to Indicators & Actuators
| ESP32 Pin | Peripheral | Purpose |
| :--- | :--- | :--- |
| **GPIO 18** | Red LED (Anode via 220Ω resistor) | Overload Alarm |
| **GPIO 19** | Green LED (Anode via 220Ω resistor) | Vehicle Permitted Pass |
| **GPIO 23** | Active Buzzer (Positive Pin) | Audible Overload Alarm |
| **GPIO 5** | Relay Input / Servo Signal | Automatic Boom Barrier Trigger |
| **GND** | Common Ground Bus | All LED & Buzzer Cathodes |

---

## 📡 Hardware Integration Flow

```text
  ┌────────────────┐
  │   LOAD CELL    │ (Weight applied by truck)
  └───────┬────────┘
          │ Microvolt differential signal
          ↓
  ┌────────────────┐
  │  HX711 AMPLIFIER│ (24-bit digital conversion)
  └───────┬────────┘
          │ DT (GPIO 21) & SCK (GPIO 22)
          ↓
  ┌────────────────┐
  │  ESP32 MCU     │ (Rolling average filter + threshold trigger)
  └───────┬────────┘
          │ Wi-Fi HTTP POST JSON: {"plate": "CG10AB1234", "weight": 14500}
          ↓
  ┌────────────────┐
  │ FASTAPI BACKEND│ (Checks RTO limit 10,000 kg -> Triggers E-Challan)
  └───────┬────────┘
          │ Returns {"is_violation": true, "fine": 30000}
          ↓
  ┌────────────────┐
  │ ESP32 ACTUATORS│ 🚨 Red LED + Buzzer Beeps + Barrier Locked
  └────────────────┘
```
