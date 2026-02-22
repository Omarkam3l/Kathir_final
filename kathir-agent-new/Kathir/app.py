"""
app.py
──────
Hugging Face Spaces entry point.

This file is required for Hugging Face Spaces deployment.
It imports and exposes the FastAPI app from main.py.
"""

from main import app

# Hugging Face Spaces will automatically run this with uvicorn
if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.getenv("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
