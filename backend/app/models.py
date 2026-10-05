"""
Pydantic Models and Schemas for Smart Overload & ANPR System.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# --- Auth Models ---
class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    token: str
    token_type: str = "bearer"
    user_id: int
    username: str
    full_name: str
    role: str
    badge_id: Optional[str] = None

class UserRegister(BaseModel):
    username: str
    password: str
    full_name: str
    role: str = "officer"
    badge_id: Optional[str] = None

# --- Vehicle Models ---
class VehicleCreate(BaseModel):
    plate_number: str
    owner_name: str
    vehicle_type: str
    permitted_weight_kg: float
    rfid_tag: Optional[str] = None
    state: str = "CG"

class VehicleResponse(BaseModel):
    id: int
    plate_number: str
    owner_name: str
    vehicle_type: str
    permitted_weight_kg: float
    rfid_tag: Optional[str] = None
    state: str
    fitness_valid_until: Optional[str] = None
    created_at: Optional[str] = None

# --- Weight Check (Hardware Input from ESP32) ---
class WeightCheckRequest(BaseModel):
    sensor_id: str = "ESP32_SCALE_01"
    plate_number: str
    measured_weight_kg: float
    checkpoint_name: str = "Raipur Bypass NH-53"

class WeightCheckResponse(BaseModel):
    record_id: int
    plate_number: str
    measured_weight_kg: float
    allowed_weight_kg: float
    excess_weight_kg: float
    status: str                         # NORMAL, WARNING, OVERLOAD
    is_violation: bool
    challan_number: Optional[str] = None
    fine_amount: float = 0.0
    message: str
    timestamp: str

# --- Violations ---
class ViolationResponse(BaseModel):
    id: int
    challan_number: str
    plate_number: str
    vehicle_type: str
    measured_weight_kg: float
    permitted_weight_kg: float
    excess_weight_kg: float
    fine_amount: float
    status: str
    checkpoint_name: str
    image_path: Optional[str] = None
    created_at: str

# --- Alerts ---
class AlertResponse(BaseModel):
    id: int
    alert_type: str
    severity: str
    plate_number: Optional[str]
    message: str
    checkpoint_name: str
    is_read: int
    created_at: str

# --- Dashboard Stats ---
class DashboardStats(BaseModel):
    total_scans_today: int
    total_violations_today: int
    total_fines_collected: float
    critical_alerts_count: int
    average_excess_weight_kg: float
    active_checkpoints_count: int
    recent_violations: List[ViolationResponse]
    recent_alerts: List[AlertResponse]
