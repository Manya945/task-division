"""
Hardware Simulator for ESP32 + Load Cell Weighbridge.
Member 4 Ownership:
Simulates ESP32 Wi-Fi transmissions to FastAPI backend:
- Can run one-off test with canonical vehicle 'CG10AB1234' (14,500 kg vs 10,000 kg)
- Can run continuous simulation loop for hackathon presentations
- Can accept interactive custom inputs
"""

import time
import random
import requests
import sys

BACKEND_URL = "http://localhost:8000/api/weight-check"
CHECKPOINT_NAME = "Raipur Highway Toll Plaza (NH-53)"

VEHICLE_FLEET = [
    {"plate": "CG10AB1234", "name": "Tata Prima 4028.S", "limit": 10000.0, "test_weight": 14500.0}, # Overload!
    {"plate": "MH12DE1433", "name": "Ashok Leyland 2820", "limit": 16200.0, "test_weight": 15400.0}, # Normal
    {"plate": "DL01AA9988", "name": "BharatBenz 3528C", "limit": 25000.0, "test_weight": 28900.0}, # Overload!
    {"plate": "KA04MN5522", "name": "Mahindra Blazo X", "limit": 12000.0, "test_weight": 11800.0}, # Normal
    {"plate": "CG04XY7890", "name": "Eicher Pro 3019", "limit": 9500.0, "test_weight": 12300.0}   # Overload!
]

def send_reading(plate: str, weight: float, sensor_id: str = "ESP32_SIMULATOR_01"):
    payload = {
        "sensor_id": sensor_id,
        "plate_number": plate,
        "measured_weight_kg": weight,
        "checkpoint_name": CHECKPOINT_NAME
    }
    print(f"\n[ESP32 SIMULATOR -> BACKEND] Transmitting reading:")
    print(f"  Vehicle: {plate} | Measured Weight: {weight:,.0f} kg")
    
    try:
        res = requests.post(BACKEND_URL, json=payload, timeout=5)
        if res.status_code == 200:
            data = res.json()
            status = data.get("status")
            is_violation = data.get("is_violation")
            excess = data.get("excess_weight_kg", 0)
            fine = data.get("fine_amount", 0)
            
            if is_violation:
                print("  [!] STATUS: >>> OVERLOAD DETECTED <<<")
                print(f"  [!] Permitted Limit: {data.get('allowed_weight_kg'):,.0f} kg")
                print(f"  [!] Excess Weight:   +{excess:,.0f} kg")
                print(f"  [!] E-Challan No:    {data.get('challan_number')}")
                print(f"  [!] Penalty Fine:    Rs. {fine:,.0f}")
                print("  [!] ESP32 Actuators: [BUZZER ON] [RED LED ON] [BARRIER LOCKED]")
            else:
                print(f"  [OK] STATUS: NORMAL ({weight:,.0f} kg / Limit {data.get('allowed_weight_kg'):,.0f} kg)")
                print("  [OK] ESP32 Actuators: [GREEN LED ON] [BARRIER OPENED]")
            return data
        else:
            print(f"  [-] Backend returned HTTP {res.status_code}: {res.text}")
    except Exception as e:
        print(f"  [-] Connection error: {e}. Is backend server running on http://localhost:8000?")
    return None

def run_canonical_demo():
    """Runs the exact overload truck scenario from the user prompt."""
    print("=" * 65)
    print("DEMO SCENARIO: OVERLOADED TRUCK (CG10AB1234)")
    print("Sensor: 14,500 kg | Allowed: 10,000 kg | Excess: 4,500 kg")
    print("=" * 65)
    return send_reading("CG10AB1234", 14500.0)

def run_continuous_stream(interval_seconds: int = 5):
    """Continuously generates simulated traffic for live dashboard demonstrations."""
    print(f"[*] Starting continuous ESP32 sensor stream (every {interval_seconds}s)... Press Ctrl+C to stop.")
    while True:
        target = random.choice(VEHICLE_FLEET)
        # Add random variation +/- 5%
        jitter = random.uniform(0.95, 1.05)
        weight = round(target["test_weight"] * jitter, 1)
        send_reading(target["plate"], weight)
        time.sleep(interval_seconds)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--stream":
        run_continuous_stream()
    elif len(sys.argv) > 2:
        plate = sys.argv[1]
        weight = float(sys.argv[2])
        send_reading(plate, weight)
    else:
        run_canonical_demo()
