<#
.SYNOPSIS
    Startet alle MCP Server und das UI Dashboard mit uv
.DESCRIPTION
    Dieses Script startet alle MCP Server mit uv:
    - MCP ADO Server (Port 8003)
    - MCP Docupedia Server (Port 8004)
    - MCP Gateway UI Dashboard
#>

$ErrorActionPreference = "Stop"

Write-Host "=== MCP Connector Launcher ===" -ForegroundColor Cyan
Write-Host ""

# Lade .env Datei wenn vorhanden
if (Test-Path ".\.env") {
    Write-Host "Lade .env Konfiguration..." -ForegroundColor Gray
    Get-Content ".\.env" | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            $key = $matches[1]
            $value = $matches[2]
            [Environment]::SetEnvironmentVariable($key, $value)
        }
    }
    Write-Host "  OK .env geladen" -ForegroundColor Green
}

$ADOColor = "Green"
$DocupediaColor = "Yellow"
$UIColor = "Magenta"

$processes = @()

try {
    # 1. MCP ADO Server starten (Port 8003)
    Write-Host "[1/3] Starte MCP ADO Server..." -ForegroundColor $ADOColor
    $adoProcess = Start-Process -FilePath "uv" -ArgumentList "run", "mcp_server.py" -WorkingDirectory ".\mcp-ado" -WindowStyle Normal -PassThru
    $processes += $adoProcess
    Write-Host "      OK MCP ADO Server gestartet (Port 8003, PID: $($adoProcess.Id))" -ForegroundColor $ADOColor
    Start-Sleep -Milliseconds 2000

    # 2. MCP Docupedia Server starten (Port 8004)
    Write-Host "[2/3] Starte MCP Docupedia Server..." -ForegroundColor $DocupediaColor
    $docupediaProcess = Start-Process -FilePath "uv" -ArgumentList "run", "mcp_server.py" -WorkingDirectory ".\mcp-docupedia" -WindowStyle Normal -PassThru
    $processes += $docupediaProcess
    Write-Host "      OK MCP Docupedia Server gestartet (Port 8004, PID: $($docupediaProcess.Id))" -ForegroundColor $DocupediaColor
    Start-Sleep -Milliseconds 2000

    # 3. Gateway Server starten (Port 8001)
    Write-Host "[3/3] Starte Gateway Server..." -ForegroundColor $UIColor
    $gatewayProcess = Start-Process -FilePath "uv" -ArgumentList "run", "gateway_server.py", "8001" -WorkingDirectory ".\mcp-gateway" -WindowStyle Normal -PassThru
    $processes += $gatewayProcess
    Write-Host "      OK Gateway Server gestartet (Port 8001, PID: $($gatewayProcess.Id))" -ForegroundColor $UIColor
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Alle Services erfolgreich gestartet!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Services:" -ForegroundColor White
    Write-Host "  MCP ADO Server:       http://localhost:8001 (PID: $($adoProcess.Id))" -ForegroundColor $ADOColor
    Write-Host "  MCP Docupedia Server: http://localhost:8002 (PID: $($docupediaProcess.Id))" -ForegroundColor $DocupediaColor
    Write-Host "  Gateway UI:           Terminal Dashboard (PID: $($uiProcess.Id))" -ForegroundColor $UIColor
    Write-Host ""
    Write-Host "Die Services laufen in separaten Fenstern." -ForegroundColor Gray
    Write-Host "Druecke Ctrl+C in diesem Fenster, um alle Services zu beenden..." -ForegroundColor Gray
    Write-Host ""

    # Warte auf Benutzer-Unterbrechung
    while ($true) {
        Start-Sleep -Seconds 2
        
        # Pruefe ob Prozesse noch laufen
        foreach ($proc in $processes) {
            $proc.Refresh()
            if ($proc.HasExited) {
                Write-Host ""
                Write-Host "WARNUNG: Prozess $($proc.Id) wurde beendet!" -ForegroundColor Red
                throw "Ein Service wurde unerwartet beendet."
            }
        }
    }
}
catch {
    if ($_.Exception.Message -notlike "*abgebrochen*") {
        Write-Host ""
        Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}
finally {
    Write-Host ""
    Write-Host "Beende alle Services..." -ForegroundColor Yellow
    
    foreach ($proc in $processes) {
        try {
            $proc.Refresh()
            if (-not $proc.HasExited) {
                Write-Host "  Stoppe Prozess $($proc.Id)..." -ForegroundColor Gray
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Prozess bereits beendet
        }
    }
    
    Write-Host "Alle Services beendet." -ForegroundColor Green
}
