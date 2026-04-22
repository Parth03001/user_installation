# =====================================================
# PERFECT AUTO-START (No Shutdown + Manual Control)
# =====================================================
 
# Execution Policy
if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}
 
 
Write-Host "🚀 AI/ML Environment..." -ForegroundColor Green
 
$env:NEO4J_HOME = "C:\Users\50017162\neo4j-community-2025.11.2-windows\neo4j-community-2025.11.2"
$env:Path = "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin:$env:Path"
$env:Path = "$env:NEO4J_HOME\bin:$env:Path"
$env:Path = "C:\Users\50017162\.local\bin;$env:Path"
 
$nodePath = "C:\Users\50017162\AppData\Local\Programs\node-v24.13.0-win-x64\node-v24.13.0-win-x64"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$nodePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$nodePath", "User")
    Write-Output "Node path added to user PATH. Restart terminal."
}
 
 
# PERFECT POSTGRES FUNCTIONS (No background issues)
function Start-Postgres {
    cd "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    Remove-Item "..\data\postmaster.pid" -Force -ErrorAction SilentlyContinue
    New-Item "..\logs" -ItemType Directory -Force | Out-Null
    .\pg_ctl.exe -D "..\data" -l "..\logs\debug.log" start -w
    Write-Host "✅ Postgres STARTED (KEEP THIS WINDOW OPEN)" -ForegroundColor Green
}
 
# Start Function
function Start-Neo4j {
    Write-Host "Starting Neo4j..." -ForegroundColor Green
    # Change to Neo4j directory
    Set-Location $env:NEO4J_HOME
    # Activate conda environment
    # conda activate env
    # Start Neo4j in console mode (this will block the terminal)
& "$env:NEO4J_HOME\bin\neo4j.bat" console
}
 
# Stop Function
function Stop-Neo4j {
    Write-Host "Stopping Neo4j..." -ForegroundColor Yellow
    # Find Neo4j Java process
    $neo4jProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -like "*neo4j*" }
    if ($neo4jProcess) {
        # Try graceful stop first
        Write-Host "Found Neo4j process (PID: $($neo4jProcess.Id)). Attempting graceful shutdown..." -ForegroundColor Cyan
        # Send stop command
        Set-Location $env:NEO4J_HOME
& "$env:NEO4J_HOME\bin\neo4j.bat" stop
        Start-Sleep -Seconds 5
        # Check if still running
        $stillRunning = Get-Process -Id $neo4jProcess.Id -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-Host "Graceful shutdown failed. Force killing process..." -ForegroundColor Red
            Stop-Process -Id $neo4jProcess.Id -Force
            Write-Host "Neo4j process killed forcefully." -ForegroundColor Red
        } else {
            Write-Host "Neo4j stopped successfully." -ForegroundColor Green
        }
    } else {
        Write-Host "No Neo4j process found running." -ForegroundColor Yellow
    }
}
 
function Stop-Postgres {
    cd "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin"
    .\pg_ctl.exe -D "..\data" stop -W
    Write-Host "✅ Postgres STOPPED" -ForegroundColor Green
}
 
 
Write-Host "`n🎯 COMMANDS READY:" -ForegroundColor Cyan
Write-Host "   Start-Postgres   ← START (keep window open!)" -ForegroundColor Yellow
Write-Host "   Stop-Postgres    ← STOP" -ForegroundColor Yellow
Write-Host "   psql -U postgres ← CONNECT" -ForegroundColor Yellow
 
Write-Host "`n🎯 COMMANDS READY:" -ForegroundColor Cyan
Write-Host "   Start-Neo4j   ← START (keep window open!)" -ForegroundColor Yellow
Write-Host "   Stop-Neo4j    ← STOP" -ForegroundColor Yellow
 
java -version | Select-Object -First 1
pg_isready -h localhost -p 5432 2>$null
node --version
 
 