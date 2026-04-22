# =============================================================
# AI/ML Environment - Start/Stop Control Script
# User: 50017162   (no admin required)
# Services: PostgreSQL | Neo4j | Node.js | OpenSearch | nginx
# =============================================================

if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Write-Host "AI/ML Environment loading..." -ForegroundColor Green

$neo4jVersion = "2026.03.1"
$nodeVersion  = "24.13.0"
$osVersion    = "3.6.0"
$nginxVersion = "1.30.0"

# ENV VARS
$env:NEO4J_HOME      = "C:\Users\50017162\neo4j-community-$neo4jVersion-windows\neo4j-community-$neo4jVersion"
$env:OPENSEARCH_HOME = "C:\Users\50017162\opensearch\opensearch-$osVersion"

# SESSION PATH (adds to current shell only)
$env:Path = "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin;$env:Path"
$env:Path = "$env:NEO4J_HOME\bin;$env:Path"
$env:Path = "$env:OPENSEARCH_HOME\bin;$env:Path"
$env:Path = "C:\Users\50017162\nginx\nginx-$nginxVersion;$env:Path"
$env:Path = "C:\Users\50017162\.local\bin;$env:Path"

# Persist Node.js to user PATH (permanent)
$nodePath = "C:\Users\50017162\AppData\Local\Programs\node-v$nodeVersion-win-x64\node-v$nodeVersion-win-x64"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$nodePath", "User")
    Write-Host "  Node path added to user PATH. Restart terminal to apply." -ForegroundColor DarkGray
}

# =============================================================
# POSTGRES
# =============================================================
function Start-Postgres {
    Set-Location "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    Remove-Item "..\data\postmaster.pid" -Force -ErrorAction SilentlyContinue
    New-Item "..\logs" -ItemType Directory -Force | Out-Null
    .\pg_ctl.exe -D "..\data" -l "..\logs\debug.log" start -w
    Write-Host "Postgres STARTED on port 5432 (keep window open)" -ForegroundColor Green
}

function Stop-Postgres {
    Set-Location "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    .\pg_ctl.exe -D "..\data" stop -W
    Write-Host "Postgres STOPPED" -ForegroundColor Green
}

# =============================================================
# NEO4J
# =============================================================
function Start-Neo4j {
    Write-Host "Starting Neo4j on ports 7474 (HTTP) / 7687 (Bolt) ..." -ForegroundColor Green
    Set-Location $env:NEO4J_HOME
    & "$env:NEO4J_HOME\bin\neo4j.bat" console
}

function Stop-Neo4j {
    Write-Host "Stopping Neo4j ..." -ForegroundColor Yellow
    $neo4jProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*neo4j*" }
    if ($neo4jProcess) {
        Write-Host "Found Neo4j (PID: $($neo4jProcess.Id)). Stopping ..." -ForegroundColor Cyan
        Set-Location $env:NEO4J_HOME
        & "$env:NEO4J_HOME\bin\neo4j.bat" stop
        Start-Sleep -Seconds 5
        $stillRunning = Get-Process -Id $neo4jProcess.Id -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Stop-Process -Id $neo4jProcess.Id -Force
            Write-Host "Neo4j force-stopped." -ForegroundColor Red
        }
        else {
            Write-Host "Neo4j stopped." -ForegroundColor Green
        }
    }
    else {
        Write-Host "No Neo4j process found." -ForegroundColor Yellow
    }
}

# =============================================================
# OPENSEARCH
# =============================================================
function Start-OpenSearch {
    Write-Host "Starting OpenSearch on port 9200 ..." -ForegroundColor Green
    $opensearchBat = "$env:OPENSEARCH_HOME\bin\opensearch.bat"
    if (-not (Test-Path $opensearchBat)) {
        Write-Host "ERROR: opensearch.bat not found at $opensearchBat" -ForegroundColor Red
        Write-Host "Make sure OpenSearch is extracted to C:\Users\50017162\opensearch\opensearch-$osVersion" -ForegroundColor Yellow
        return
    }
    Set-Location $env:OPENSEARCH_HOME
    # Set OPENSEARCH_JAVA_OPTS for lower memory in dev
    $env:OPENSEARCH_JAVA_OPTS = "-Xms512m -Xmx512m"
    & $opensearchBat
}

function Stop-OpenSearch {
    Write-Host "Stopping OpenSearch ..." -ForegroundColor Yellow
    $osProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*opensearch*" }
    if ($osProcess) {
        Stop-Process -Id $osProcess.Id -Force
        Write-Host "OpenSearch stopped (PID: $($osProcess.Id))." -ForegroundColor Green
    }
    else {
        Write-Host "No OpenSearch process found." -ForegroundColor Yellow
    }
}

function Get-OpenSearchStatus {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:9200" -Method Get -TimeoutSec 3
        Write-Host "OpenSearch is UP - cluster: $($r.cluster_name) version: $($r.version.number)" -ForegroundColor Green
    }
    catch {
        Write-Host "OpenSearch is DOWN or not reachable on port 9200." -ForegroundColor Red
    }
}

# =============================================================
# NGINX
# =============================================================
function Start-Nginx {
    $nginxExe = "C:\Users\50017162\nginx\nginx-$nginxVersion\nginx.exe"
    if (-not (Test-Path $nginxExe)) {
        Write-Host "ERROR: nginx.exe not found at $nginxExe" -ForegroundColor Red
        return
    }
    Set-Location "C:\Users\50017162\nginx\nginx-$nginxVersion"
    Start-Process -FilePath $nginxExe -WorkingDirectory "C:\Users\50017162\nginx\nginx-$nginxVersion" -WindowStyle Hidden
    Start-Sleep -Seconds 1
    $check = Get-Process nginx -ErrorAction SilentlyContinue
    if ($check) {
        Write-Host "nginx STARTED on port 8080." -ForegroundColor Green
        Write-Host "  http://localhost:8080/opensearch/ -> OpenSearch :9200" -ForegroundColor DarkGray
        Write-Host "  http://localhost:8080/neo4j/      -> Neo4j :7474" -ForegroundColor DarkGray
    }
    else {
        Write-Host "nginx may have failed to start. Check logs:" -ForegroundColor Red
        Write-Host "  C:\Users\50017162\nginx\nginx-$nginxVersion\logs\error.log" -ForegroundColor Yellow
    }
}

function Stop-Nginx {
    $nginxExe = "C:\Users\50017162\nginx\nginx-$nginxVersion\nginx.exe"
    if (Test-Path $nginxExe) {
        Set-Location "C:\Users\50017162\nginx\nginx-$nginxVersion"
        & $nginxExe -s stop
        Write-Host "nginx STOPPED." -ForegroundColor Green
    }
    else {
        $nginxProcs = Get-Process nginx -ErrorAction SilentlyContinue
        if ($nginxProcs) {
            $nginxProcs | Stop-Process -Force
            Write-Host "nginx processes killed." -ForegroundColor Green
        }
        else {
            Write-Host "No nginx process found." -ForegroundColor Yellow
        }
    }
}

function Reload-Nginx {
    $nginxExe = "C:\Users\50017162\nginx\nginx-$nginxVersion\nginx.exe"
    Set-Location "C:\Users\50017162\nginx\nginx-$nginxVersion"
    & $nginxExe -s reload
    Write-Host "nginx config reloaded." -ForegroundColor Green
}

# =============================================================
# SHORTCUTS: start / stop everything at once
# =============================================================
function Start-All {
    Write-Host "Starting all services ..." -ForegroundColor Cyan
    Start-Postgres
    Start-OpenSearch
    Start-Nginx
    Write-Host "Start Neo4j separately with: Start-Neo4j (it blocks the terminal)" -ForegroundColor Yellow
}

function Stop-All {
    Stop-Nginx
    Stop-OpenSearch
    Stop-Neo4j
    Stop-Postgres
}

# =============================================================
Write-Host ""
Write-Host "COMMANDS READY:" -ForegroundColor Cyan
Write-Host "  Start-Postgres     /  Stop-Postgres     (port 5432)" -ForegroundColor Yellow
Write-Host "  Start-Neo4j        /  Stop-Neo4j        (port 7474 / 7687)" -ForegroundColor Yellow
Write-Host "  Start-OpenSearch   /  Stop-OpenSearch   (port 9200)" -ForegroundColor Yellow
Write-Host "  Start-Nginx        /  Stop-Nginx        (port 8080)" -ForegroundColor Yellow
Write-Host "  Reload-Nginx       /  Get-OpenSearchStatus" -ForegroundColor Yellow
Write-Host "  Start-All          /  Stop-All" -ForegroundColor Yellow
Write-Host "  psql -U postgres" -ForegroundColor Yellow
Write-Host ""

# Quick status check
java -version 2>&1 | Select-Object -First 1
pg_isready -h localhost -p 5432 2>$null
node --version
