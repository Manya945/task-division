"""
Lightweight Authentication & Token Utility for Smart Overload System.
Supports clean session tokens and role-based access.
"""

import hashlib
import secrets
from typing import Optional, Dict

# In-memory session store: token -> user_dict
ACTIVE_SESSIONS: Dict[str, dict] = {}

def hash_password(password: str) -> str:
    """Hashes a password with SHA-256 and fixed salt for hackathon/demo simplicity."""
    salt = "hackbios_smart_overload_2026"
    return hashlib.sha256((password + salt).encode('utf-8')).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against hashed password."""
    return hash_password(plain_password) == hashed_password

def create_access_token(user_data: dict) -> str:
    """Generates a secure random session token."""
    token = secrets.token_urlsafe(32)
    ACTIVE_SESSIONS[token] = user_data
    return token

def get_current_user(token: str) -> Optional[dict]:
    """Retrieves user info from token."""
    return ACTIVE_SESSIONS.get(token)
