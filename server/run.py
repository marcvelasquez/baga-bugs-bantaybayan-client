import subprocess
import sys

# Run uvicorn with uv's Python environment
subprocess.run([
    sys.executable, 
    "-m", 
    "uvicorn", 
    "app.main:app",
    "--reload",
    "--host", "0.0.0.0",
    "--port", "8000"
])
