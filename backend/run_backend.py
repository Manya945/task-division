"""
Runner script to launch FastAPI Backend Server for Smart Overload & ANPR System.
"""

import sys
import os
import uvicorn

# Ensure the app directory is in python path
APP_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app")
sys.path.insert(0, APP_DIR)

if __name__ == "__main__":
    print("=" * 60)
    print("[*] SMART OVERLOAD & ANPR DETECTION SYSTEM BACKEND")
    print("[*] Running on: http://localhost:8000")
    print("[*] Interactive Swagger Docs: http://localhost:8000/docs")
    print("[*] Real-time Dashboard: http://localhost:8000/")
    print("=" * 60)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
