"""
Member 4: End-to-End System Integration and Regression Test Suite.
Verifies full pipeline across all 4 team modules:
- Member 1: REST API client expectations
- Member 2: FastAPI Backend + Database integrity + Fine calculation
- Member 3: AI/ANPR plate detection & OCR rectification
- Member 4: ESP32 Hardware weight injection & event alerts
"""

import os
import sys
import unittest
from datetime import datetime

# Add app paths
BACKEND_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend")
APP_DIR = os.path.join(BACKEND_DIR, "app")
ANPR_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "anpr_engine")
sys.path.insert(0, APP_DIR)
sys.path.insert(0, ANPR_DIR)

from fastapi.testclient import TestClient
from main import app
from anpr_processor import anpr_service
from database import get_db_connection

client = TestClient(app)

class TestSmartOverloadIntegration(unittest.TestCase):

    def test_01_health_and_docs(self):
        """Verifies API server is responsive and docs are generated."""
        res = client.get("/docs")
        self.assertEqual(res.status_code, 200)

    def test_02_auth_login(self):
        """Verifies RTO officer authentication."""
        res = client.post("/api/login", json={"username": "rto_admin", "password": "admin123"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("token", data)
        self.assertEqual(data["username"], "rto_admin")
        self.assertEqual(data["role"], "admin")

    def test_03_canonical_overload_flow(self):
        """
        Executes the exact scenario from user's specification:
        Truck: CG10AB1234
        Limit: 10,000 kg
        Measured: 14,500 kg
        Expected: OVERLOAD, Excess: 4,500 kg, Fine: Rs. 30,000, Violation & Alert generated
        """
        # Step 1: ESP32 sends weight
        weight_payload = {
            "sensor_id": "ESP32_INTEGRATION_TEST_01",
            "plate_number": "CG10AB1234",
            "measured_weight_kg": 14500.0,
            "checkpoint_name": "Raipur Highway Toll Plaza (NH-53)"
        }
        res = client.post("/api/weight-check", json=weight_payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()

        self.assertEqual(data["plate_number"], "CG10AB1234")
        self.assertEqual(data["measured_weight_kg"], 14500.0)
        self.assertEqual(data["allowed_weight_kg"], 10000.0)
        self.assertEqual(data["excess_weight_kg"], 4500.0)
        self.assertEqual(data["status"], "OVERLOAD")
        self.assertTrue(data["is_violation"])
        self.assertIsNotNone(data["challan_number"])
        self.assertEqual(data["fine_amount"], 30000.0) # Base 20,000 + 5 tonnes * 2,000 = 30,000

        # Step 2: Verify in Violations API
        v_res = client.get("/api/violations")
        self.assertEqual(v_res.status_code, 200)
        violations = v_res.json()
        self.assertTrue(any(v["challan_number"] == data["challan_number"] for v in violations))

        # Step 3: Verify in Alerts API
        a_res = client.get("/api/alerts")
        self.assertEqual(a_res.status_code, 200)
        alerts = a_res.json()
        self.assertTrue(any("CG10AB1234" in (a["plate_number"] or "") for a in alerts))

    def test_04_normal_weight_flow(self):
        """Verifies legal weight truck produces NORMAL status and no violation."""
        weight_payload = {
            "sensor_id": "ESP32_TEST_02",
            "plate_number": "MH12DE1433",
            "measured_weight_kg": 15000.0, # Limit is 16,200 kg
            "checkpoint_name": "Raipur Highway Toll Plaza (NH-53)"
        }
        res = client.post("/api/weight-check", json=weight_payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "NORMAL")
        self.assertFalse(data["is_violation"])
        self.assertEqual(data["excess_weight_kg"], 0.0)
        self.assertEqual(data["fine_amount"], 0.0)

    def test_05_anpr_camera_scan_integration(self):
        """Verifies ANPR OCR recognition + simultaneous weight check."""
        sample_img = os.path.join(ANPR_DIR, "sample_images", "CG10AB1234.png")
        self.assertTrue(os.path.exists(sample_img))

        with open(sample_img, "rb") as f:
            res = client.post(
                "/api/anpr/scan",
                files={"file": ("CG10AB1234.png", f, "image/png")},
                data={"simulated_weight": 14500.0}
            )

        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["plate_number"], "CG10AB1234")
        self.assertIsNotNone(data["weight_check"])
        self.assertEqual(data["weight_check"]["status"], "OVERLOAD")

    def test_06_dashboard_statistics(self):
        """Verifies dashboard aggregates records properly."""
        res = client.get("/api/dashboard/stats")
        self.assertEqual(res.status_code, 200)
        stats = res.json()
        self.assertGreaterEqual(stats["total_scans_today"], 2)
        self.assertGreaterEqual(stats["total_violations_today"], 1)

if __name__ == "__main__":
    unittest.main()
