from pathlib import Path
import sys

PROJECT_BACKEND_DIR = Path(__file__).resolve().parents[1] / "backend" / "rentory_api"
if str(PROJECT_BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_BACKEND_DIR))

from app.main import app
