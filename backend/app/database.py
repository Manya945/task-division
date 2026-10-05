"""
Database setup and schema for Smart Overload & ANPR Detection System.
Uses SQLite for zero-config, portable, and fast local persistence.
"""

import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "smart_overload.db")

def get_db_connection():
    """Returns a SQLite connection with dict-like row factory."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initializes tables for Users, Vehicles, Weight Records, Violations, Alerts, Locations."""
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Users Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'officer', -- 'admin', 'officer', 'operator'
        badge_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 2. Vehicles Registry Table (VAHAN Integration simulation)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate_number TEXT UNIQUE NOT NULL,
        owner_name TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,           -- 'Heavy Commercial', 'Medium Truck', 'Multi-Axle Trailer'
        permitted_weight_kg REAL NOT NULL,    -- Allowed Gross Vehicle Weight (GVW)
        rfid_tag TEXT,
        state TEXT NOT NULL DEFAULT 'CG',
        fitness_valid_until DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 3. Weight Records Table (Real-time ESP32 sensor logs)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS weight_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate_number TEXT NOT NULL,
        measured_weight_kg REAL NOT NULL,
        allowed_weight_kg REAL NOT NULL,
        excess_weight_kg REAL NOT NULL,
        status TEXT NOT NULL,                 -- 'NORMAL', 'WARNING', 'OVERLOAD'
        sensor_id TEXT NOT NULL,              -- e.g. 'ESP32_SCALE_01'
        checkpoint_name TEXT NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 4. Violations Table (E-Challan records)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS violations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challan_number TEXT UNIQUE NOT NULL,
        plate_number TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        measured_weight_kg REAL NOT NULL,
        permitted_weight_kg REAL NOT NULL,
        excess_weight_kg REAL NOT NULL,
        fine_amount REAL NOT NULL,            -- Base ₹20,000 + ₹2,000 per excess tonne
        status TEXT NOT NULL DEFAULT 'PENDING',-- 'PENDING', 'PAID', 'DISPUTED'
        checkpoint_name TEXT NOT NULL,
        image_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 5. Alerts Table (Real-time notifications for Officers)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alert_type TEXT NOT NULL,             -- 'CRITICAL_OVERLOAD', 'UNREGISTERED_PLATE', 'SENSOR_OFFLINE'
        severity TEXT NOT NULL DEFAULT 'HIGH',-- 'CRITICAL', 'HIGH', 'MEDIUM', 'INFO'
        plate_number TEXT,
        message TEXT NOT NULL,
        checkpoint_name TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 6. Checkpoint Locations Table (Map Coordinates)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checkpoint_code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        highway TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        active_officers INTEGER DEFAULT 2
    );
    """)

    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()
    print("Database schema initialized successfully at:", DB_PATH)
