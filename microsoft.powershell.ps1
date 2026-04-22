# =============================================================
# AI/ML Environment - Start/Stop Control Script
# User: 50017162   (no admin required)
# =============================================================

if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Write-Host "AI/ML Environment loading..." -ForegroundColor Green

$neo4jVersion = "2025.11.0"
$nodeVersion  = "24.13.0"

$env:NEO4J_HOME = "C:\Users\50017162\neo4j-community-$neo4jVersion-windows\neo4j-community-$neo4jVersion"
$env:Path = "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin;$env:Path"
$env:Path = "$env:NEO4J_HOME\bin;$env:Path"
$env:Path = "C:\Users\50017162\.local\bin;$env:Path"

$nodePath = "C:\Users\50017162\AppData\Local\Programs\node-v$nodeVersion-win-x64\node-v$nodeVersion-win-x64"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$nodePath", "User")
    Write-Output "Node path added to user PATH. Restart terminal to apply."
}

# =============================================================
# POSTGRES FUNCTIONS
# =============================================================
function Start-Postgres {
    Set-Location "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    Remove-Item "..\data\postmaster.pid" -Force -ErrorAction SilentlyContinue
    New-Item "..\logs" -ItemType Directory -Force | Out-Null
    .\pg_ctl.exe -D "..\data" -l "..\logs\debug.log" start -w
    Write-Host "Postgres STARTED (keep this window open)" -ForegroundColor Green
}

function Stop-Postgres {
    Set-Location "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    .\pg_ctl.exe -D "..\data" stop -W
    Write-Host "Postgres STOPPED" -ForegroundColor Green
}

# =============================================================
# NEO4J FUNCTIONS
# =============================================================
function Start-Neo4j {
    Write-Host "Starting Neo4j..." -ForegroundColor Green
    Set-Location $env:NEO4J_HOME
    & "$env:NEO4J_HOME\bin\neo4j.bat" console
}

function Stop-Neo4j {
    Write-Host "Stopping Neo4j..." -ForegroundColor Yellow
    $neo4jProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*neo4j*" }
    if ($neo4jProcess) {
        Write-Host "Found Neo4j (PID: $($neo4jProcess.Id)). Stopping..." -ForegroundColor Cyan
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
Write-Host ""
Write-Host "COMMANDS READY:" -ForegroundColor Cyan
Write-Host "  Start-Postgres   /  Stop-Postgres" -ForegroundColor Yellow
Write-Host "  psql -U postgres" -ForegroundColor Yellow
Write-Host "  Start-Neo4j      /  Stop-Neo4j" -ForegroundColor Yellow
Write-Host ""

java -version 2>&1 | Select-Object -First 1
pg_isready -h localhost -p 5432 2>$null
node --version
