"""
Seed Data Script: Populates initial sample records for demo, presentation & testing.
Includes realistic Indian commercial vehicles, checkpoints, and initial violation data.
"""

from database import init_db, get_db_connection
from auth import hash_password

def seed_all():
    init_db()
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Seed Default Users
    users = [
        ("rto_admin", hash_password("admin123"), "Inspector Rajesh Verma", "admin", "CG-RTO-001"),
        ("officer_sharma", hash_password("officer123"), "Sub-Inspector Amit Sharma", "officer", "CG-RTO-104"),
        ("operator_singh", hash_password("pass123"), "Weighbridge Operator Karan Singh", "operator", "CG-WB-209")
    ]
    for u in users:
        cursor.execute("""
            INSERT OR IGNORE INTO users (username, password_hash, full_name, role, badge_id)
            VALUES (?, ?, ?, ?, ?)
        """, u)

    # 2. Seed VAHAN Registered Commercial Vehicles
    vehicles = [
        ("CG10AB1234", "Balaji Freight Logistics Ltd.", "Tata Prima 4028.S (Heavy Truck)", 10000.0, "RFID_CG_1001", "CG", "2027-12-31"),
        ("MH12DE1433", "Sahyadri Roadlines Corp.", "Ashok Leyland 2820 (Multi-Axle)", 16200.0, "RFID_MH_2004", "MH", "2028-06-15"),
        ("DL01AA9988", "Northern Express Cargo", "BharatBenz 3528C (Heavy Tipper)", 25000.0, "RFID_DL_3008", "DL", "2027-09-20"),
        ("KA04MN5522", "Deccan Minerals Transport", "Mahindra Blazo X 28 (Carrier)", 12000.0, "RFID_KA_4012", "KA", "2028-01-10"),
        ("CG04XY7890", "Chhattisgarh Coal Haulers", "Eicher Pro 3019 (Medium Truck)", 9500.0, "RFID_CG_5015", "CG", "2027-11-05")
    ]
    for v in vehicles:
        cursor.execute("""
            INSERT OR IGNORE INTO vehicles (plate_number, owner_name, vehicle_type, permitted_weight_kg, rfid_tag, state, fitness_valid_until)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, v)

    # 3. Seed Checkpoint Locations
    locations = [
        ("CP-CG-01", "Raipur Highway Toll Plaza (NH-53)", "NH-53 National Highway", 21.2514, 81.6296, "ACTIVE", 3),
        ("CP-CG-02", "Bilaspur Industrial Bypass", "SH-10 State Highway", 22.0797, 82.1409, "ACTIVE", 2),
        ("CP-CG-03", "Durg-Bhilai Industrial Corridor", "NH-53 / GE Road", 21.1904, 81.2849, "ACTIVE", 2),
        ("CP-CG-04", "Nagpur-Rajnandgaon Inter-State Border", "NH-53 Border Checkpost", 21.0963, 80.9547, "ACTIVE", 4)
    ]
    for loc in locations:
        cursor.execute("""
            INSERT OR IGNORE INTO locations (checkpoint_code, name, highway, latitude, longitude, status, active_officers)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, loc)

    # 4. Seed Past Sample Weight Records and Violations
    past_records = [
        ("MH12DE1433", 15800.0, 16200.0, 0.0, "NORMAL", "ESP32_SCALE_01", "Raipur Highway Toll Plaza (NH-53)"),
        ("KA04MN5522", 11950.0, 12000.0, 0.0, "NORMAL", "ESP32_SCALE_02", "Bilaspur Industrial Bypass"),
        ("DL01AA9988", 24800.0, 25000.0, 0.0, "NORMAL", "ESP32_SCALE_01", "Raipur Highway Toll Plaza (NH-53)"),
        ("CG04XY7890", 11800.0, 9500.0, 2300.0, "OVERLOAD", "ESP32_SCALE_03", "Durg-Bhilai Industrial Corridor"),
    ]
    for r in past_records:
        cursor.execute("""
            INSERT INTO weight_records (plate_number, measured_weight_kg, allowed_weight_kg, excess_weight_kg, status, sensor_id, checkpoint_name)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, r)

    # Initial Violation
    cursor.execute("""
        INSERT OR IGNORE INTO violations (challan_number, plate_number, vehicle_type, measured_weight_kg, permitted_weight_kg, excess_weight_kg, fine_amount, status, checkpoint_name)
        VALUES ('ECH-CG-2026-001', 'CG04XY7890', 'Eicher Pro 3019 (Medium Truck)', 11800.0, 9500.0, 2300.0, 24600.0, 'PENDING', 'Durg-Bhilai Industrial Corridor')
    """)

    # Initial Alert
    cursor.execute("""
        INSERT INTO alerts (alert_type, severity, plate_number, message, checkpoint_name, is_read)
        VALUES ('CRITICAL_OVERLOAD', 'CRITICAL', 'CG04XY7890', 'Overweight vehicle detected (+2,300 kg excess). E-Challan generated.', 'Durg-Bhilai Industrial Corridor', 0)
    """)

    conn.commit()
    conn.close()
    print("Database successfully seeded with realistic Indian transport data!")

if __name__ == "__main__":
    seed_all()
