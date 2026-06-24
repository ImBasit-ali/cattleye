# Start cattle-ai Python backend, stopping a previous instance on the same port.
# Usage (from repo root):  .\scripts\start_backend.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Read-BackendPort {
    param([string]$EnvFile)
    $port = 8000
    if (-not (Test-Path $EnvFile)) { return $port }
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*PORT\s*=\s*(\d+)\s*$') { $port = [int]$Matches[1] }
    }
    return $port
}

function Get-ListeningPids {
    param([int]$Port)
    $pattern = ":$Port\s"
    netstat -ano | Select-String $pattern | ForEach-Object {
        $line = $_.Line.Trim()
        if ($line -match 'LISTENING\s+(\d+)\s*$') { $Matches[1] }
    } | Select-Object -Unique
}

$envFile = Join-Path $Root "python_backend\.env"
$port = Read-BackendPort -EnvFile $envFile

foreach ($procId in Get-ListeningPids -Port $port) {
    if ($procId -eq "0") { continue }

    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue
    $cmd = if ($proc) { $proc.CommandLine } else { "" }

    if ($cmd -match 'python_backend\.main|uvicorn.*python_backend') {
        Write-Host "Stopping previous cattle-ai backend (PID $procId) on port $port..."
        Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
        continue
    }

    if ($cmd -match 'manage\.py\s+runserver|django') {
        Write-Error @"
Port $port is already used by Django (PID $procId).
Stop Django first, or change PORT in python_backend\.env and LOCAL_MODEL_BACKEND_URL in .env (e.g. port 8010).
"@
    }

    Write-Error @"
Port $port is already in use (PID $procId).
Stop that process first, or change PORT in python_backend\.env and LOCAL_MODEL_BACKEND_URL in .env to match.
Command: $cmd
"@
}

Start-Sleep -Seconds 1

Write-Host "Starting cattle-ai backend on http://127.0.0.1:$port ..."
python -m uvicorn python_backend.main:app --host 0.0.0.0 --port $port
