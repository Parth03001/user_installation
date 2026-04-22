# =============================================================
# USER INSTALLATION SCRIPT  (No Admin Required)
# User : 50017162
# Tools: PostgreSQL 17.4 | Neo4j 2025.11.2 | Node.js 24.13.0
#
# DOWNLOAD LINKS (manual fallback if auto-download fails):
#
#   PostgreSQL 17.4 binaries zip (no installer):
#     https://get.enterprisedb.com/postgresql/postgresql-17.4-1-windows-x64-binaries.zip
#
#   Neo4j Community 2025.11.2 zip:
#     https://dist.neo4j.org/neo4j-community-2025.11.2-windows.zip
#
#   Node.js v24.13.0 zip (no installer):
#     https://nodejs.org/dist/v24.13.0/node-v24.13.0-win-x64.zip
#
#   Java 21 zip (required by Neo4j, no installer):
#     https://github.com/adoptium/temurin21-binaries/releases/latest
#     (pick the Windows x64 .zip asset)
# =============================================================

# Allow scripts for current user only - no admin needed
if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Write-Host "" -ForegroundColor Green
Write-Host " AI/ML Stack Installer - user 50017162 (no admin)" -ForegroundColor Green
Write-Host " PostgreSQL 17.4 | Neo4j 2025.11.2 | Node.js v24.13.0" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkGray
Write-Host "" -ForegroundColor Green

# -------------------------------------------------------------
# VERSION CONFIG
# -------------------------------------------------------------
$pgBuild      = "17.4-1"
$neo4jVersion = "2025.11.2"
$nodeVersion  = "24.13.0"

# -------------------------------------------------------------
# PATHS  (must match microsoft.powershell.ps1)
# -------------------------------------------------------------
$userRoot    = "C:\Users\50017162"
$dlDir       = "$userRoot\Downloads\_installs"

# PostgreSQL - EDB binaries zip extracts a "pgsql" folder
$pgExtractTo = "$userRoot\PostgreSQL\pgsql"
$pgBinDir    = "$pgExtractTo\pgsql\bin"
$pgDataDir   = "$pgExtractTo\pgsql\data"
$pgLogsDir   = "$pgExtractTo\pgsql\logs"
$pgZipUrl    = "https://get.enterprisedb.com/postgresql/postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZip       = "$dlDir\postgresql-$pgBuild-windows-x64-binaries.zip"

# Neo4j - zip contains neo4j-community-2025.11.2\
$neo4jExtract = "$userRoot\neo4j-community-$neo4jVersion-windows"
$neo4jHome    = "$neo4jExtract\neo4j-community-$neo4jVersion"
$neo4jZipUrl  = "https://dist.neo4j.org/neo4j-community-$neo4jVersion-windows.zip"
$neo4jZip     = "$dlDir\neo4j-community-$neo4jVersion-windows.zip"

# Node.js - zip contains node-v24.13.0-win-x64\
$nodeExtract  = "$userRoot\AppData\Local\Programs\node-v$nodeVersion-win-x64"
$nodeBinDir   = "$nodeExtract\node-v$nodeVersion-win-x64"
$nodeZipUrl   = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip"
$nodeZip      = "$dlDir\node-v$nodeVersion-win-x64.zip"

# -------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------
function Get-ZipFile {
    param(
        [string]$Url,
        [string]$Dest,
        [string]$Label
    )
    if (Test-Path $Dest) {
        Write-Host "  [skip] $Label already downloaded." -ForegroundColor DarkGray
        return
    }
    Write-Host "  Downloading $Label ..." -ForegroundColor Yellow
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($Url, $Dest)
        Write-Host "  OK -> $Dest" -ForegroundColor Green
    }
    catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Manual URL: $Url" -ForegroundColor Cyan
    }
}

function Expand-ZipFile {
    param(
        [string]$ZipPath,
        [string]$DestDir,
        [string]$Label
    )
    if (Test-Path $DestDir) {
        $count = (Get-ChildItem $DestDir -ErrorAction SilentlyContinue).Count
        if ($count -gt 0) {
            Write-Host "  [skip] $Label already extracted." -ForegroundColor DarkGray
            return
        }
    }
    Write-Host "  Extracting $Label ..." -ForegroundColor Yellow
    New-Item $DestDir -ItemType Directory -Force | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force
    Write-Host "  OK -> $DestDir" -ForegroundColor Green
}

function Add-ToUserPath {
    param([string]$Dir)
    $cur = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($cur -notlike "*$Dir*") {
        [Environment]::SetEnvironmentVariable("Path", "$cur;$Dir", "User")
        Write-Host "  PATH += $Dir" -ForegroundColor Cyan
    }
    else {
        Write-Host "  [skip] Already in PATH: $Dir" -ForegroundColor DarkGray
    }
}

# -------------------------------------------------------------
# STEP 1 - Create directories
# -------------------------------------------------------------
Write-Host "[1/6] Creating directories ..." -ForegroundColor Cyan
New-Item $dlDir       -ItemType Directory -Force | Out-Null
New-Item $pgExtractTo -ItemType Directory -Force | Out-Null
New-Item $neo4jExtract -ItemType Directory -Force | Out-Null
New-Item $nodeExtract  -ItemType Directory -Force | Out-Null
New-Item "$userRoot\.local\bin" -ItemType Directory -Force | Out-Null
Write-Host "  Done." -ForegroundColor Green

# -------------------------------------------------------------
# STEP 2 - Download zips
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Cyan
Write-Host "[2/6] Downloading packages ..." -ForegroundColor Cyan
Get-ZipFile -Url $pgZipUrl    -Dest $pgZip    -Label "PostgreSQL $pgBuild"
Get-ZipFile -Url $neo4jZipUrl -Dest $neo4jZip -Label "Neo4j $neo4jVersion"
Get-ZipFile -Url $nodeZipUrl  -Dest $nodeZip  -Label "Node.js v$nodeVersion"

# -------------------------------------------------------------
# STEP 3 - Extract zips
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Cyan
Write-Host "[3/6] Extracting packages ..." -ForegroundColor Cyan
if (Test-Path $pgZip)    { Expand-ZipFile -ZipPath $pgZip    -DestDir $pgExtractTo  -Label "PostgreSQL" }
if (Test-Path $neo4jZip) { Expand-ZipFile -ZipPath $neo4jZip -DestDir $neo4jExtract -Label "Neo4j" }
if (Test-Path $nodeZip)  { Expand-ZipFile -ZipPath $nodeZip  -DestDir $nodeExtract  -Label "Node.js" }

# -------------------------------------------------------------
# STEP 4 - Initialize PostgreSQL data directory
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Cyan
Write-Host "[4/6] Initializing PostgreSQL ..." -ForegroundColor Cyan
if (Test-Path "$pgDataDir\PG_VERSION") {
    Write-Host "  [skip] Data directory already initialized." -ForegroundColor DarkGray
}
else {
    $initdb = "$pgBinDir\initdb.exe"
    if (Test-Path $initdb) {
        New-Item $pgDataDir -ItemType Directory -Force | Out-Null
        New-Item $pgLogsDir -ItemType Directory -Force | Out-Null
        & $initdb -D $pgDataDir -U postgres -E UTF8 --locale=en_US.UTF-8
        Write-Host "  PostgreSQL data dir ready: $pgDataDir" -ForegroundColor Green
    }
    else {
        Write-Host "  WARNING: initdb.exe not found - extraction may have failed." -ForegroundColor Red
        Write-Host "  Expected path: $initdb" -ForegroundColor DarkGray
    }
}

# -------------------------------------------------------------
# STEP 5 - Set user environment variables
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Cyan
Write-Host "[5/6] Setting user environment variables ..." -ForegroundColor Cyan

[Environment]::SetEnvironmentVariable("NEO4J_HOME", $neo4jHome, "User")
Write-Host "  NEO4J_HOME = $neo4jHome" -ForegroundColor Green

Add-ToUserPath -Dir $pgBinDir
Add-ToUserPath -Dir "$neo4jHome\bin"
Add-ToUserPath -Dir $nodeBinDir
Add-ToUserPath -Dir "$userRoot\.local\bin"

# -------------------------------------------------------------
# STEP 6 - Java check (Neo4j 2025.x requires Java 21+)
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Cyan
Write-Host "[6/6] Checking Java ..." -ForegroundColor Cyan
$javaOk = $false
try {
    $jv = & java -version 2>&1 | Select-String "version"
    if ($jv) {
        Write-Host "  Java found: $jv" -ForegroundColor Green
        $javaOk = $true
    }
}
catch {}

if (-not $javaOk) {
    Write-Host "  Java NOT found. Neo4j 2025.x requires Java 21+." -ForegroundColor Red
    Write-Host "  Download Java 21 zip (no installer):" -ForegroundColor Yellow
    Write-Host "  https://github.com/adoptium/temurin21-binaries/releases/latest" -ForegroundColor Cyan
    Write-Host "  Pick: OpenJDK21U-jdk_x64_windows_hotspot_21.x.x.zip" -ForegroundColor Yellow
    Write-Host "  Extract to: $userRoot\java21" -ForegroundColor Yellow
    Write-Host "  Then add to PATH: $userRoot\java21\jdk-21.x.x\bin" -ForegroundColor Yellow
    Write-Host "  Then re-run this script." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# SUMMARY
# -------------------------------------------------------------
Write-Host "" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  PostgreSQL  $pgBuild  -> $pgBinDir" -ForegroundColor White
Write-Host "  Neo4j       $neo4jVersion -> $neo4jHome\bin" -ForegroundColor White
Write-Host "  Node.js     v$nodeVersion  -> $nodeBinDir" -ForegroundColor White
Write-Host "" -ForegroundColor Cyan
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell (PATH is now updated)" -ForegroundColor Yellow
Write-Host "  2. Dot-source the control script:" -ForegroundColor Yellow
Write-Host "       . .\microsoft.powershell.ps1" -ForegroundColor White
Write-Host "  3. Use these commands:" -ForegroundColor Yellow
Write-Host "       Start-Postgres   /  Stop-Postgres" -ForegroundColor White
Write-Host "       Start-Neo4j      /  Stop-Neo4j" -ForegroundColor White
Write-Host "       psql -U postgres" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Green
