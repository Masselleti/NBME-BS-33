# Medicine Academy - Local HTTP Server
# PowerShell HTTP Server (No Python Required!)

param(
    [int]$Port = 5550,
    [string]$Path = "."
)

function Get-AvailablePort {
    param([int]$PreferredPort = 5550)
    
    $testListener = [System.Net.HttpListener]::new()
    try {
        $testListener.Prefixes.Add("http://localhost:$PreferredPort/")
        $testListener.Start()
        $testListener.Stop()
        return $PreferredPort
    }
    catch {
        Write-Host ""
        Write-Host " [!] Port $PreferredPort is in use!" -ForegroundColor Yellow
        Write-Host " [*] Finding available port..." -ForegroundColor Cyan
        
        for ($i = 0; $i -lt 100; $i++) {
            $randomPort = Get-Random -Minimum 5551 -Maximum 10000
            
            try {
                $newListener = [System.Net.HttpListener]::new()
                $newListener.Prefixes.Add("http://localhost:$randomPort/")
                $newListener.Start()
                $newListener.Stop()
                
                Write-Host " [+] Found available port: $randomPort" -ForegroundColor Green
                return $randomPort
            }
            catch {
                continue
            }
        }
        
        throw "Could not find available port after 100 attempts"
    }
}

# Check for required files
function Test-RequiredFiles {
    $requiredFiles = @(
        "index.html",
        "js/sql-wasm.js",
        "js/sql-wasm.wasm"
    )
    
    $missing = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missing += $file
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host " [!] WARNING: Missing required files:" -ForegroundColor Yellow
        foreach ($file in $missing) {
            Write-Host "   - $file" -ForegroundColor Red
        }
        Write-Host " The application may not work correctly." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }
}

$Port = Get-AvailablePort -PreferredPort $Port

# Set window title
$Host.UI.RawUI.WindowTitle = "Medicine Academy Server - Port $Port"

# Print banner
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "         Medicine Academy - Local Server v2.0" -ForegroundColor Green
Write-Host "" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $Path
$AbsolutePath = (Get-Location).Path

# Check for required files
Test-RequiredFiles

$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:$Port/")

try {
    $http.Start()
    
    $url = "http://localhost:$Port"
    Write-Host " [*] Server URL:" -ForegroundColor Green
    Write-Host "     $url" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " [*] Serving folder:" -ForegroundColor Green
    Write-Host "     $AbsolutePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " [i] Tip: Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # Open browser
    Start-Process $url
    
    while ($http.IsListening) {
        $context = $http.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($request.HttpMethod) " -NoNewline -ForegroundColor Cyan
        Write-Host "$($request.Url.LocalPath)" -ForegroundColor White
        
        $requestedPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($requestedPath)) {
            $requestedPath = "index.html"
        }
        
        $filePath = Join-Path $AbsolutePath $requestedPath
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            
            # MIME types with WASM support
            $mimeTypes = @{
                '.html' = 'text/html; charset=utf-8'
                '.css'  = 'text/css; charset=utf-8'
                '.js'   = 'application/javascript; charset=utf-8'
                '.mjs'  = 'application/javascript; charset=utf-8'
                '.json' = 'application/json; charset=utf-8'
                '.wasm' = 'application/wasm'
                '.db'   = 'application/octet-stream'
                '.sqlite' = 'application/octet-stream'
                '.png'  = 'image/png'
                '.jpg'  = 'image/jpeg'
                '.jpeg' = 'image/jpeg'
                '.gif'  = 'image/gif'
                '.webp' = 'image/webp'
                '.svg'  = 'image/svg+xml'
                '.ico'  = 'image/x-icon'
                '.txt'  = 'text/plain; charset=utf-8'
                '.pdf'  = 'application/pdf'
                '.xml'  = 'application/xml; charset=utf-8'
                '.woff' = 'font/woff'
                '.woff2' = 'font/woff2'
                '.ttf'  = 'font/ttf'
                '.eot'  = 'application/vnd.ms-fontobject'
                '.mp4'  = 'video/mp4'
                '.webm' = 'video/webm'
                '.mp3'  = 'audio/mpeg'
                '.wav'  = 'audio/wav'
            }
            
            if ($mimeTypes.ContainsKey($extension)) {
                $response.ContentType = $mimeTypes[$extension]
            } else {
                $response.ContentType = 'application/octet-stream'
            }
            
            # Add CORS headers
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache")
            
            $response.StatusCode = 200
            $response.OutputStream.Write($content, 0, $content.Length)
        }
        elseif (Test-Path $filePath -PathType Container) {
            $items = Get-ChildItem $filePath | Sort-Object {$_.PSIsContainer}, Name -Descending
            
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index of /$requestedPath</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        header {
            background: linear-gradient(135deg, #0b4a6f 0%, #0e5a87 100%);
            color: white;
            padding: 30px;
            border-bottom: 4px solid rgba(255,255,255,0.2);
        }
        h1 { 
            font-size: 24px; 
            font-weight: 600;
            margin-bottom: 8px;
        }
        .subtitle {
            opacity: 0.9;
            font-size: 14px;
        }
        table { 
            width: 100%; 
            border-collapse: collapse; 
        }
        thead {
            background: #f8fafc;
            border-bottom: 2px solid #e2e8f0;
        }
        th { 
            padding: 16px 20px; 
            text-align: left; 
            font-weight: 600;
            color: #334155;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        td { 
            padding: 14px 20px; 
            border-bottom: 1px solid #f1f5f9;
            color: #475569;
        }
        tr:hover td { 
            background: #f8fafc; 
        }
        a { 
            color: #0b4a6f; 
            text-decoration: none;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        a:hover { 
            color: #0e5a87;
            text-decoration: underline; 
        }
        .size, .modified { 
            color: #94a3b8;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Index of /$requestedPath</h1>
            <div class="subtitle">Medicine Academy Local Server</div>
        </header>
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Size</th>
                    <th>Modified</th>
                </tr>
            </thead>
            <tbody>
"@
            
            if ($requestedPath -ne "") {
                $html += "<tr><td><a href='../'>[ Parent Directory ]</a></td><td>-</td><td>-</td></tr>"
            }
            
            foreach ($item in $items) {
                $name = $item.Name
                $href = $name
                $size = if ($item.PSIsContainer) { "-" } else { "{0:N2} MB" -f ($item.Length / 1MB) }
                $modified = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                $displayName = if ($item.PSIsContainer) { "[FOLDER] $name"; $href += "/" } else { $name }
                
                $html += "<tr><td><a href='$href'>$displayName</a></td><td class='size'>$size</td><td class='modified'>$modified</td></tr>"
            }
            
            $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = 'text/html; charset=utf-8'
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>404 - Not Found</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
        }
        .error-box {
            background: white;
            padding: 60px;
            border-radius: 20px;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            font-size: 72px;
            color: #ef4444;
            margin: 0 0 20px 0;
        }
        p {
            color: #64748b;
            font-size: 18px;
        }
        code {
            background: #f1f5f9;
            padding: 4px 8px;
            border-radius: 4px;
            color: #334155;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="error-box">
        <h1>404</h1>
        <p>File not found</p>
        <p><code>$requestedPath</code></p>
    </div>
</body>
</html>
"@
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = 'text/html; charset=utf-8'
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 404
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
}
catch {
    Write-Host ""
    Write-Host " [X] Error: $_" -ForegroundColor Red
    Write-Host ""
}
finally {
    $http.Stop()
    Write-Host ""
    Write-Host " [!] Server stopped" -ForegroundColor Yellow
    Write-Host ""
}
