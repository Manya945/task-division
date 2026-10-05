"""
Generates realistic Indian High Security Registration Plates (HSRP)
for testing the ANPR engine and live camera scans.
"""

import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sample_images")
os.makedirs(OUTPUT_DIR, exist_ok=True)

SAMPLE_PLATES = [
    {"plate": "CG10AB1234", "bg": (255, 204, 0), "fg": (0, 0, 0), "label": "Commercial Truck (CG)"},
    {"plate": "MH12DE1433", "bg": (255, 204, 0), "fg": (0, 0, 0), "label": "Heavy Trailer (MH)"},
    {"plate": "DL01AA9988", "bg": (255, 204, 0), "fg": (0, 0, 0), "label": "Interstate Carrier (DL)"},
    {"plate": "KA04MN5522", "bg": (255, 255, 255), "fg": (0, 0, 0), "label": "Private Carrier (KA)"}
]

def generate_plate_image(plate_text: str, bg_color=(255, 204, 0), fg_color=(0, 0, 0)) -> str:
    """Creates a photorealistic HSRP plate graphic."""
    width = 460
    height = 140
    img = Image.new('RGB', (width, height), color=(240, 240, 240))
    draw = ImageDraw.Draw(img)

    # Outer border (black)
    draw.rectangle([5, 5, width - 5, height - 5], outline=(30, 30, 30), width=4)
    # Inner Plate Background
    draw.rectangle([8, 8, width - 8, height - 8], fill=bg_color)

    # Blue HSRP Left Stripe (IND flag strip)
    draw.rectangle([8, 8, 48, height - 8], fill=(0, 51, 153))
    # Draw simple yellow chakra circle
    draw.ellipse([20, 25, 36, 41], fill=(255, 204, 0))
    # IND text on stripe
    draw.text((15, 60), "IND", fill=(255, 255, 255))

    # Formatted display with spaces: "CG 10 AB 1234"
    if len(plate_text) >= 9:
        formatted = f"{plate_text[:2]} {plate_text[2:4]} {plate_text[4:6]} {plate_text[6:]}"
    else:
        formatted = plate_text

    # Draw Plate Text
    draw.text((80, 40), formatted, fill=fg_color)
    
    # Bottom security hologram mark
    draw.rectangle([70, 95, 95, 115], fill=(180, 180, 180), outline=(100, 100, 100))

    out_file = os.path.join(OUTPUT_DIR, f"{plate_text}.png")
    img.save(out_file)
    return out_file

if __name__ == "__main__":
    print(f"Generating {len(SAMPLE_PLATES)} sample plates in {OUTPUT_DIR}...")
    for item in SAMPLE_PLATES:
        path = generate_plate_image(item["plate"], item["bg"], item["fg"])
        print(f"-> Generated {item['plate']} ({item['label']}): {path}")
