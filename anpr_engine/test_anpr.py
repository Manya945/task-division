"""
Member 3 Unit Test Suite for ANPR Engine.
Tests plate rectification, regex extraction, and image analysis.
"""

import os
import unittest
from anpr_processor import anpr_service, rectify_indian_plate, clean_ocr_text

class TestANPREngine(unittest.TestCase):
    def test_rectification(self):
        # OCR confusion tests:
        # '0' in state code should become 'O' or valid state
        # 'O' in RTO code should become '0'
        raw = "CG1OAB1234"
        rectified = rectify_indian_plate(raw)
        self.assertEqual(rectified, "CG10AB1234")

        # Test standard spacing
        spaced = "MH 12 DE 1433"
        self.assertEqual(rectify_indian_plate(spaced), "MH12DE1433")

        # Test lowercase
        lower = "dl01aa9988"
        self.assertEqual(rectify_indian_plate(lower), "DL01AA9988")

    def test_sample_image_extraction(self):
        sample_path = os.path.join(os.path.dirname(__file__), "sample_images", "CG10AB1234.png")
        self.assertTrue(os.path.exists(sample_path))
        with open(sample_path, "rb") as f:
            data = f.read()
        res = anpr_service.extract_plate_from_bytes(data, filename_hint="CG10AB1234.png")
        self.assertTrue(res["success"])
        self.assertEqual(res["plate_number"], "CG10AB1234")
        self.assertEqual(res["state_code"], "CG")
        self.assertEqual(res["state_name"], "Chhattisgarh")
        print("Image OCR Test Passed:", res)

if __name__ == "__main__":
    unittest.main()
