#!/bin/bash
# Medicine Academy Launcher for macOS
# Double-click this file to start the server

cd "$(dirname "$0")/.."

echo ""
echo "=========================================="
echo "   Medicine Academy - Starting Server"
echo "=========================================="
echo ""

# Check if Python 3 is installed
if command -v python3 &> /dev/null; then
    echo "✓ Python 3 found"
    python3 assets/start.py
elif command -v python &> /dev/null; then
    # Check if it's Python 3
    if python --version 2>&1 | grep -q "Python 3"; then
        echo "✓ Python found"
        python assets/start.py
    else
        echo "❌ Error: Python 3 is required but not found"
        echo ""
        echo "Please install Python 3:"
        echo "1. Open Terminal"
        echo "2. Run: brew install python3"
        echo "   (or download from python.org)"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi
else
    echo "❌ Error: Python is not installed"
    echo ""
    echo "Please install Python 3:"
    echo "1. Visit https://www.python.org/downloads/"
    echo "2. Download and install Python 3"
    echo "3. Or use Homebrew: brew install python3"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi
