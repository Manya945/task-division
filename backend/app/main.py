"""
FastAPI Backend Application for Smart Overload & ANPR Detection System.
Member 2 Ownership:
- Central Brain & REST API Gateway
- Weight calculation & Motor Vehicles Act fine calculation
- E-Challan generation & violation management
- Real-time WebSocket broadcasting for live dashboard and mobile app
- Integration with Member 3 (ANPR Engine) & Member 4 (ESP32 Sensor)
"""

import os
import sys
import math
import secrets
from datetime import datetime
from typing import List, Optional

from fastapi import FastAPI, HTTPException, Depends, Header, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse, FileResponse

# Add ANPR engine directory to sys.path
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANPR_DIR = os.path.join(os.path.dirname(BASE_DIR), "anpr_engine")
WEB_DIR = os.path.join(os.path.dirname(BASE_DIR), "web_dashboard")
sys.path.append(ANPR_DIR)

try:
    from app.database import get_db_connection, init_db
    from app.models import (
        LoginRequest, LoginResponse, UserRegister,
        VehicleCreate, VehicleResponse,
        WeightCheckRequest, WeightCheckResponse,
        ViolationResponse, AlertResponse, DashboardStats
    )
    from app.auth import hash_password, verify_password, create_access_token, get_current_user
except ImportError:
    from database import get_db_connection, init_db
    from models import (
        LoginRequest, LoginResponse, UserRegister,
        VehicleCreate, VehicleResponse,
        WeightCheckRequest, WeightCheckResponse,
        ViolationResponse, AlertResponse, DashboardStats
    )
    from auth import hash_password, verify_password, create_access_token, get_current_user
from anpr_processor import anpr_service, rectify_indian_plate

app = FastAPI(
    title="Smart Overload & ANPR Detection System API",
    description="Automated Weigh-in-Motion (WIM), ANPR camera feed, and E-Challan generation platform.",
    version="2.0.0"
)

# Enable CORS for Flutter mobile apps and external frontends
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Active WebSocket connections manager for live updates
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                pass

manager = ConnectionManager()

# Auth dependency
def authenticate_token(authorization: Optional[str] = Header(None)) -> Optional[dict]:
    if not authorization:
        return None
    token = authorization.replace("Bearer ", "").strip()
    return get_current_user(token)

@app.on_event("startup")
def startup_event():
    init_db()
    print("[BACKEND] Database initialized and API ready on port 8000.")

# ==============================================================================
# 1. AUTHENTICATION APIS (/login, /register)
# ==============================================================================

@app.post("/api/login", response_model=LoginResponse)
@app.post("/api/auth/login", response_model=LoginResponse)
def login(creds: LoginRequest):
    conn = get_db_connection()
    user = conn.execute("SELECT * FROM users WHERE username = ?", (creds.username,)).fetchone()
    conn.close()

    if not user or not verify_password(creds.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    user_dict = {
        "id": user["id"],
        "username": user["username"],
        "full_name": user["full_name"],
        "role": user["role"],
        "badge_id": user["badge_id"]
    }
    token = create_access_token(user_dict)

    return LoginResponse(
        token=token,
        user_id=user["id"],
        username=user["username"],
        full_name=user["full_name"],
        role=user["role"],
        badge_id=user["badge_id"]
    )

@app.post("/api/auth/register")
def register_officer(reg: UserRegister):
    conn = get_db_connection()
    try:
        conn.execute("""
            INSERT INTO users (username, password_hash, full_name, role, badge_id)
            VALUES (?, ?, ?, ?, ?)
        """, (reg.username, hash_password(reg.password), reg.full_name, reg.role, reg.badge_id))
        conn.commit()
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=400, detail=f"Username already exists or error: {e}")
    conn.close()
    return {"success": True, "message": f"User {reg.username} registered successfully"}

# ==============================================================================
# 2. VEHICLES REGISTRY APIS (/vehicles)
# ==============================================================================

@app.get("/api/vehicles", response_model=List[VehicleResponse])
def list_vehicles():
    conn = get_db_connection()
    rows = conn.execute("SELECT * FROM vehicles ORDER BY id DESC").fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.get("/api/vehicles/{plate_number}")
def get_vehicle(plate_number: str):
    clean_plate = rectify_indian_plate(plate_number) or plate_number.upper().replace(" ", "")
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM vehicles WHERE plate_number = ?", (clean_plate,)).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail=f"Vehicle {plate_number} not found in VAHAN registry")
    return dict(row)

@app.post("/api/vehicles", response_model=VehicleResponse)
def register_vehicle(veh: VehicleCreate):
    clean_plate = rectify_indian_plate(veh.plate_number) or veh.plate_number.upper().replace(" ", "")
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO vehicles (plate_number, owner_name, vehicle_type, permitted_weight_kg, rfid_tag, state)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (clean_plate, veh.owner_name, veh.vehicle_type, veh.permitted_weight_kg, veh.rfid_tag, veh.state))
        conn.commit()
        new_id = cursor.lastrowid
        row = conn.execute("SELECT * FROM vehicles WHERE id = ?", (new_id,)).fetchone()
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=400, detail=f"Vehicle registration error: {e}")
    conn.close()
    return dict(row)

# ==============================================================================
# 3. WEIGHT-CHECK & MOTOR VEHICLES ACT ENGINE (/weight-check)
# ==============================================================================

def calculate_overload_fine(excess_kg: float) -> float:
    """
    Motor Vehicles (Amendment) Act 2019 - Overloading Penalty:
    Base Fine: Rs. 20,000
    Additional Fine: Rs. 2,000 per metric tonne (or part thereof) over permissible limit.
    """
    if excess_kg <= 0:
        return 0.0
    excess_tonnes = math.ceil(excess_kg / 1000.0)
    return 20000.0 + (excess_tonnes * 2000.0)

@app.post("/api/weight-check", response_model=WeightCheckResponse)
async def process_weight_check(check: WeightCheckRequest):
    clean_plate = rectify_indian_plate(check.plate_number) or check.plate_number.upper().replace(" ", "")
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Lookup vehicle in database or create default entry if new
    veh = conn.execute("SELECT * FROM vehicles WHERE plate_number = ?", (clean_plate,)).fetchone()
    if veh:
        permitted_limit = veh["permitted_weight_kg"]
        veh_type = veh["vehicle_type"]
    else:
        # Default fallback standard commercial GVW: 10,000 kg
        permitted_limit = 10000.0
        veh_type = "Commercial Goods Carrier"
        cursor.execute("""
            INSERT OR IGNORE INTO vehicles (plate_number, owner_name, vehicle_type, permitted_weight_kg, state)
            VALUES (?, ?, ?, ?, ?)
        """, (clean_plate, "Registered Transporter", veh_type, permitted_limit, clean_plate[:2]))
        conn.commit()

    measured_weight = check.measured_weight_kg
    excess_weight = round(max(0.0, measured_weight - permitted_limit), 2)

    # Determine status
    if excess_weight > 0:
        status = "OVERLOAD"
        is_violation = True
    elif measured_weight >= (0.95 * permitted_limit):
        status = "WARNING"
        is_violation = False
    else:
        status = "NORMAL"
        is_violation = False

    # 2. Record reading in weight_records
    cursor.execute("""
        INSERT INTO weight_records (plate_number, measured_weight_kg, allowed_weight_kg, excess_weight_kg, status, sensor_id, checkpoint_name)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (clean_plate, measured_weight, permitted_limit, excess_weight, status, check.sensor_id, check.checkpoint_name))
    record_id = cursor.lastrowid

    challan_no = None
    fine_amount = 0.0

    # 3. If Overloaded, automatically generate E-Challan & Alert
    if is_violation:
        fine_amount = calculate_overload_fine(excess_weight)
        challan_no = f"ECH-CG-{datetime.now().year}-{secrets.randbelow(89999) + 10000}"
        
        cursor.execute("""
            INSERT INTO violations (challan_number, plate_number, vehicle_type, measured_weight_kg, permitted_weight_kg, excess_weight_kg, fine_amount, status, checkpoint_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)
        """, (challan_no, clean_plate, veh_type, measured_weight, permitted_limit, excess_weight, fine_amount, check.checkpoint_name))

        # Alert for Mobile App and Control Room
        alert_msg = f"OVERLOAD ALERT: {clean_plate} exceeds limit by {int(excess_weight):,} kg! Fine: Rs.{int(fine_amount):,}."
        cursor.execute("""
            INSERT INTO alerts (alert_type, severity, plate_number, message, checkpoint_name, is_read)
            VALUES ('CRITICAL_OVERLOAD', 'CRITICAL', ?, ?, ?, 0)
        """, (clean_plate, alert_msg, check.checkpoint_name))

    conn.commit()
    conn.close()

    response_payload = {
        "record_id": record_id,
        "plate_number": clean_plate,
        "measured_weight_kg": measured_weight,
        "allowed_weight_kg": permitted_limit,
        "excess_weight_kg": excess_weight,
        "status": status,
        "is_violation": is_violation,
        "challan_number": challan_no,
        "fine_amount": fine_amount,
        "message": f"Overload of {int(excess_weight)} kg detected! E-Challan issued." if is_violation else "Weight is within permissible limits.",
        "timestamp": datetime.now().isoformat()
    }

    # Broadcast event to WebSocket subscribers (Dashboard & App)
    await manager.broadcast({
        "event": "WEIGHT_RECORDED",
        "data": response_payload
    })

    return WeightCheckResponse(**response_payload)

# ==============================================================================
# 4. VIOLATIONS APIS (/violations)
# ==============================================================================

@app.get("/api/violations", response_model=List[ViolationResponse])
def get_violations(limit: int = 50, status: Optional[str] = None):
    conn = get_db_connection()
    if status:
        rows = conn.execute("SELECT * FROM violations WHERE status = ? ORDER BY id DESC LIMIT ?", (status, limit)).fetchall()
    else:
        rows = conn.execute("SELECT * FROM violations ORDER BY id DESC LIMIT ?", (limit,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.get("/api/violations/{violation_id}")
def get_violation_details(violation_id: int):
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM violations WHERE id = ?", (violation_id,)).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Violation not found")
    return dict(row)

@app.patch("/api/violations/{violation_id}/pay")
async def pay_violation_challan(violation_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE violations SET status = 'PAID' WHERE id = ?", (violation_id,))
    conn.commit()
    conn.close()
    
    await manager.broadcast({"event": "CHALLAN_PAID", "violation_id": violation_id})
    return {"success": True, "message": f"Challan #{violation_id} marked as PAID"}

# ==============================================================================
# 5. ALERTS APIS (/alerts)
# ==============================================================================

@app.get("/api/alerts", response_model=List[AlertResponse])
def get_alerts(unread_only: bool = False, limit: int = 30):
    conn = get_db_connection()
    if unread_only:
        rows = conn.execute("SELECT * FROM alerts WHERE is_read = 0 ORDER BY id DESC LIMIT ?", (limit,)).fetchall()
    else:
        rows = conn.execute("SELECT * FROM alerts ORDER BY id DESC LIMIT ?", (limit,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.post("/api/alerts/acknowledge/{alert_id}")
def acknowledge_alert(alert_id: int):
    conn = get_db_connection()
    conn.execute("UPDATE alerts SET is_read = 1 WHERE id = ?", (alert_id,))
    conn.commit()
    conn.close()
    return {"success": True, "message": f"Alert #{alert_id} acknowledged"}

# ==============================================================================
# 6. HISTORY & AUDIT APIS (/history)
# ==============================================================================

@app.get("/api/history")
def get_weight_history(limit: int = 50, plate: Optional[str] = None):
    conn = get_db_connection()
    if plate:
        rows = conn.execute("SELECT * FROM weight_records WHERE plate_number = ? ORDER BY id DESC LIMIT ?", (plate, limit)).fetchall()
    else:
        rows = conn.execute("SELECT * FROM weight_records ORDER BY id DESC LIMIT ?", (limit,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]

# ==============================================================================
# 7. DASHBOARD STATS API (/api/dashboard/stats)
# ==============================================================================

@app.get("/api/dashboard/stats", response_model=DashboardStats)
def get_dashboard_stats():
    conn = get_db_connection()
    total_scans = conn.execute("SELECT COUNT(*) FROM weight_records").fetchone()[0]
    total_violations = conn.execute("SELECT COUNT(*) FROM violations").fetchone()[0]
    fines_collected = conn.execute("SELECT COALESCE(SUM(fine_amount), 0) FROM violations WHERE status = 'PAID'").fetchone()[0]
    critical_alerts = conn.execute("SELECT COUNT(*) FROM alerts WHERE severity = 'CRITICAL' AND is_read = 0").fetchone()[0]
    avg_excess = conn.execute("SELECT COALESCE(AVG(excess_weight_kg), 0) FROM weight_records WHERE status = 'OVERLOAD'").fetchone()[0]
    checkpoints = conn.execute("SELECT COUNT(*) FROM locations WHERE status = 'ACTIVE'").fetchone()[0]

    recent_violations = conn.execute("SELECT * FROM violations ORDER BY id DESC LIMIT 5").fetchall()
    recent_alerts = conn.execute("SELECT * FROM alerts ORDER BY id DESC LIMIT 5").fetchall()
    conn.close()

    return DashboardStats(
        total_scans_today=total_scans,
        total_violations_today=total_violations,
        total_fines_collected=float(fines_collected),
        critical_alerts_count=critical_alerts,
        average_excess_weight_kg=round(float(avg_excess), 1),
        active_checkpoints_count=checkpoints,
        recent_violations=[dict(v) for v in recent_violations],
        recent_alerts=[dict(a) for a in recent_alerts]
    )

# ==============================================================================
# 8. CHECKPOINT LOCATIONS (/api/locations)
# ==============================================================================

@app.get("/api/locations")
def get_locations():
    conn = get_db_connection()
    rows = conn.execute("SELECT * FROM locations").fetchall()
    conn.close()
    return [dict(r) for r in rows]

# ==============================================================================
# 9. ANPR / SCAN ENDPOINT (Connected with Member 3)
# ==============================================================================

@app.post("/api/anpr/scan")
async def scan_vehicle_plate(
    file: Optional[UploadFile] = File(None),
    plate_hint: Optional[str] = Form(None),
    simulated_weight: Optional[float] = Form(None),
    checkpoint_name: str = Form("Raipur Highway Toll Plaza (NH-53)")
):
    """
    End-to-End ANPR + Weighbridge Scanner:
    1. Receives image upload or camera snapshot.
    2. Runs AI OCR plate detection.
    3. Cross-references vehicle permitted weight.
    4. Triggers weight check and violation if overweight.
    """
    detected_plate = plate_hint
    ocr_result = None

    if file:
        file_bytes = await file.read()
        ocr_result = anpr_service.extract_plate_from_bytes(file_bytes, filename_hint=file.filename or "")
        detected_plate = ocr_result["plate_number"]
    elif not detected_plate:
        # Fallback to standard demo truck
        detected_plate = "CG10AB1234"

    detected_plate = rectify_indian_plate(detected_plate) or detected_plate

    # If weight was also provided by load cell during the scan:
    weight_result = None
    if simulated_weight is not None and simulated_weight > 0:
        weight_result = await process_weight_check(WeightCheckRequest(
            sensor_id="ANPR_INTEGRATED_CAM_01",
            plate_number=detected_plate,
            measured_weight_kg=simulated_weight,
            checkpoint_name=checkpoint_name
        ))

    # Lookup vehicle details
    conn = get_db_connection()
    veh_row = conn.execute("SELECT * FROM vehicles WHERE plate_number = ?", (detected_plate,)).fetchone()
    conn.close()

    return {
        "success": True,
        "plate_number": detected_plate,
        "ocr_details": ocr_result or {"confidence": 0.96, "engine": "Direct Scan"},
        "vehicle_info": dict(veh_row) if veh_row else None,
        "weight_check": weight_result.model_dump() if weight_result else None
    }

# ==============================================================================
# 10. WEBSOCKET REAL-TIME BROADCAST
# ==============================================================================

@app.websocket("/ws/live-feed")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep connection alive & listen for client pings
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Mount static web dashboard if directory exists
if os.path.exists(WEB_DIR):
    app.mount("/dashboard", StaticFiles(directory=WEB_DIR, html=True), name="web_dashboard")
    @app.get("/")
    def index():
        return FileResponse(os.path.join(WEB_DIR, "index.html"))
