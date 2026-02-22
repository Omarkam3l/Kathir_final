@echo off
echo ========================================
echo Boss Food Ordering - Starting Server
echo ========================================
echo.
echo Starting FastAPI server...
echo.
echo The Chat UI will be available at:
echo   http://localhost:8000/
echo.
echo API Documentation:
echo   http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m uvicorn main:app --reload
