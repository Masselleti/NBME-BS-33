#!/usr/bin/env python3
"""
Medicine Academy - Cross-Platform HTTP Server
Works on: Windows, macOS, Linux

Just double-click this file or run: python3 start.py
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

# Configuration
PORT = 5550
HOST = "localhost"

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Enhanced HTTP handler with proper MIME types for WASM and databases"""
    
    extensions_map = {
        # Web standards
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.xml': 'application/xml',
        
        # WASM (CRITICAL for SQL.js)
        '.wasm': 'application/wasm',
        
        # Databases
        '.db': 'application/octet-stream',
        '.sqlite': 'application/octet-stream',
        
        # Images
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        
        # Fonts
        '.woff': 'font/woff',
        '.woff2': 'font/woff2',
        '.ttf': 'font/ttf',
        '.otf': 'font/otf',
        '.eot': 'application/vnd.ms-fontobject',
        
        # Media
        '.mp4': 'video/mp4',
        '.webm': 'video/webm',
        '.mp3': 'audio/mpeg',
        '.wav': 'audio/wav',
        
        # Documents
        '.pdf': 'application/pdf',
        '.txt': 'text/plain',
        
        # Default
        '': 'application/octet-stream',
    }
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
    
    def log_message(self, format, *args):
        """Override to add colored output"""
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))


def find_available_port(preferred_port):
    """Find an available port, starting with the preferred one"""
    import socket
    
    for port in range(preferred_port, preferred_port + 100):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind((HOST, port))
                return port
        except OSError:
            continue
    
    raise RuntimeError(f"Could not find available port in range {preferred_port}-{preferred_port + 100}")


def check_required_files():
    """Check if required files exist"""
    required_files = [
        'index.html',
        'js/sql-wasm.js',
        'js/sql-wasm.wasm'
    ]
    
    missing = []
    for file in required_files:
        if not Path(file).exists():
            missing.append(file)
    
    if missing:
        print("\n⚠️  WARNING: Missing required files:")
        for file in missing:
            print(f"   - {file}")
        print("\nThe application may not work correctly.\n")
        input("Press Enter to continue anyway, or Ctrl+C to cancel...")
        print()


def main():
    """Start the HTTP server"""
    print("\n" + "=" * 60)
    print("        Medicine Academy - Question Bank Server")
    print("                  Cross-Platform Edition")
    print("=" * 60 + "\n")
    
    # Change to script directory
    os.chdir(Path(__file__).parent.parent)
    
    # Check required files
    check_required_files()
    
    # Find available port
    try:
        port = find_available_port(PORT)
    except RuntimeError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    
    if port != PORT:
        print(f"⚠️  Port {PORT} is in use, using port {port} instead\n")
    
    # Create server
    handler = CustomHTTPRequestHandler
    
    try:
        with socketserver.TCPServer((HOST, port), handler) as httpd:
            url = f"http://{HOST}:{port}"
            
            print(f"✅ Server started successfully!")
            print(f"\n📍 URL: {url}")
            print(f"📁 Serving: {os.getcwd()}")
            print(f"\n💡 Press Ctrl+C to stop the server")
            print("=" * 60 + "\n")
            
            # Open browser
            print("🌐 Opening browser...")
            webbrowser.open(url)
            
            # Serve forever
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        print("=" * 60 + "\n")
        sys.exit(0)
    
    except Exception as e:
        print(f"\n❌ Error: {e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
