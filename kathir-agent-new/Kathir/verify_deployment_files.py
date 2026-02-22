#!/usr/bin/env python3
"""
Verify all required files are present for Hugging Face deployment.
Run this before deploying to ensure nothing is missing.
"""

import os
from pathlib import Path

# Required files for deployment
REQUIRED_FILES = [
    "Dockerfile",
    "requirements.txt",
    "main.py",
    "app.py",
    ".dockerignore",
]

# Required directories
REQUIRED_DIRS = [
    "src",
    "src/api",
    "src/tools",
    "src/utils",
]

# Required source files
REQUIRED_SRC_FILES = [
    "src/__init__.py",
    "src/boss_agent.py",
    "src/prompts.py",
    "src/api/__init__.py",
    "src/api/routes_agent.py",
    "src/api/routes_cart.py",
    "src/api/routes_favorites.py",
    "src/api/routes_health.py",
    "src/api/routes_meals.py",
    "src/tools/__init__.py",
    "src/tools/budget.py",
    "src/tools/cart.py",
    "src/tools/favorites.py",
    "src/tools/meals.py",
    "src/utils/__init__.py",
    "src/utils/auth.py",
    "src/utils/db_client.py",
    "src/utils/embeddings.py",
    "src/utils/filters.py",
    "src/utils/formatters.py",
    "src/utils/nutrition.py",
    "src/utils/time_utils.py",
]

# Required static files
REQUIRED_STATIC_FILES = []

# Environment variables that should be set in Hugging Face Spaces
REQUIRED_ENV_VARS = [
    "OPENROUTER_API_KEY",
    "HF_TOKEN",
    "SUPABASE_URL",
    "SUPABASE_KEY",
]


def check_file(filepath):
    """Check if a file exists."""
    if os.path.isfile(filepath):
        size = os.path.getsize(filepath)
        return True, f"✓ {filepath} ({size} bytes)"
    else:
        return False, f"✗ {filepath} - MISSING"


def check_dir(dirpath):
    """Check if a directory exists."""
    if os.path.isdir(dirpath):
        return True, f"✓ {dirpath}/"
    else:
        return False, f"✗ {dirpath}/ - MISSING"


def main():
    print("=" * 70)
    print("HUGGING FACE DEPLOYMENT VERIFICATION")
    print("=" * 70)
    print()
    
    all_ok = True
    
    # Check root files
    print("📄 ROOT FILES:")
    print("-" * 70)
    for filepath in REQUIRED_FILES:
        ok, msg = check_file(filepath)
        print(msg)
        if not ok:
            all_ok = False
    print()
    
    # Check directories
    print("📁 DIRECTORIES:")
    print("-" * 70)
    for dirpath in REQUIRED_DIRS:
        ok, msg = check_dir(dirpath)
        print(msg)
        if not ok:
            all_ok = False
    print()
    
    # Check source files
    print("🐍 SOURCE FILES:")
    print("-" * 70)
    for filepath in REQUIRED_SRC_FILES:
        ok, msg = check_file(filepath)
        print(msg)
        if not ok:
            all_ok = False
    print()
    
    # Check static files
    if REQUIRED_STATIC_FILES:
        print("🎨 STATIC FILES:")
        print("-" * 70)
        for filepath in REQUIRED_STATIC_FILES:
            ok, msg = check_file(filepath)
            print(msg)
            if not ok:
                all_ok = False
        print()
    else:
        print("🎨 STATIC FILES:")
        print("-" * 70)
        print("✓ No static files (API-only deployment)")
        print()
    
    # Check environment variables
    print("🔑 ENVIRONMENT VARIABLES:")
    print("-" * 70)
    print("These should be set in Hugging Face Space secrets:")
    for var in REQUIRED_ENV_VARS:
        value = os.getenv(var)
        if value:
            print(f"✓ {var} - Set locally")
        else:
            print(f"⚠ {var} - Not set locally (set in HF Space secrets)")
    print()
    
    # Summary
    print("=" * 70)
    if all_ok:
        print("✅ ALL REQUIRED FILES PRESENT - READY FOR DEPLOYMENT!")
        print()
        print("Next steps:")
        print("1. Go to https://huggingface.co/new-space")
        print("2. Choose 'Docker' as SDK")
        print("3. Upload all files listed above")
        print("4. Set environment variables in Space secrets")
        print("5. Wait for build to complete")
        print("6. Test your deployment!")
    else:
        print("❌ SOME FILES ARE MISSING - PLEASE FIX BEFORE DEPLOYMENT")
        print()
        print("Missing files must be created before deployment.")
    print("=" * 70)
    
    return 0 if all_ok else 1


if __name__ == "__main__":
    exit(main())
