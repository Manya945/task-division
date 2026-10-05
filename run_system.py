"""
Master System Launcher for Smart Overload & ANPR Detection System.
Launches:
- Member 2 Backend + SQLite DB
- Member 3 ANPR Integration
- Member 4 Hardware Gateway
- Member 1 Web Interface & API for Flutter App
"""

import os
import sys
import webbrowser
import threading
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(BASE_DIR, "backend", "app")
sys.path.insert(0, APP_DIR)
sys.path.insert(0, os.path.join(BASE_DIR, "backend"))
sys.path.insert(0, os.path.join(BASE_DIR, "anpr_engine"))

from seed_data import seed_all
import uvicorn

def open_browser():
    time.sleep(1.5)
    try:
        webbrowser.open("http://localhost:8000")
    except Exception:
        pass

if __name__ == "__main__":
    print("=" * 70)
    print("  SURAKSHA WIM - SMART OVERLOAD & ANPR DETECTION SYSTEM")
    print("  4-Member Integrated Architecture (Hackbios 2026)")
    print("=" * 70)
    
    # 1. Initialize and seed database
    print("\n[*] Initializing SQLite Database with VAHAN vehicles and checkpoints...")
    seed_all()

    # 2. Launch browser automatically in background
    print("[*] Launching Web Control Room at http://localhost:8000 ...")
    threading.Thread(target=open_browser, daemon=True).start()

    # 3. Start Uvicorn Server
    print("[*] Starting FastAPI Server on port 8000...")
    print("[*] Interactive Swagger API Docs: http://localhost:8000/docs")
    print("[*] Press Ctrl+C to stop.\n")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
