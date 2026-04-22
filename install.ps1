# =====================================================
# USER INSTALLATION SCRIPT  (No Admin Required)
# User : 50017162
# Tools: PostgreSQL 17.4 · Neo4j 2025.11.2 · Node.js 24.13.0
#
# DOWNLOAD LINKS (save these for manual download if needed)
#   PostgreSQL 17.4 binaries (zip, no installer):
#     https://get.enterprisedb.com/postgresql/postgresql-17.4-1-windows-x64-binaries.zip
#
#   Neo4j Community 2025.11.2 (zip):
#     https://dist.neo4j.org/neo4j-community-2025.11.2-windows.zip
#
#   Node.js v24.13.0 (zip, no installer):
#     https://nodejs.org/dist/v24.13.0/node-v24.13.0-win-x64.zip
#
#   Java 21 (required by Neo4j, zip, no installer):
#     https://github.com/adoptium/temurin21-binaries/releases/latest
#     (pick Windows x64 .zip asset)
# =====================================================

# Allow scripts for current user only (no admin)
if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Write-Host "`n AI/ML Stack Installer – user 50017162 (no admin)" -ForegroundColor Green
Write-Host " PostgreSQL 17.4 | Neo4j 2025.11.2 | Node.js v24.13.0" -ForegroundColor Cyan
Write-Host "====================================================`n" -ForegroundColor DarkGray

# ─── VERSION CONFIG ────────────────────────────────────────────────────────────
$pgBuild      = "17.4-1"
$neo4jVersion = "2025.11.2"
$nodeVersion  = "24.13.0"

# ─── PATHS (must match microsoft.powershell.ps1) ───────────────────────────────
$userRoot     = "C:\Users\50017162"
$dlDir        = "$userRoot\Downloads\_installs"

# PostgreSQL  – EDB binaries zip extracts a "pgsql" folder
$pgExtractTo  = "$userRoot\PostgreSQL\pgsql"        # zip extracts here → pgsql\pgsql\...
$pgBinDir     = "$pgExtractTo\pgsql\bin"
$pgDataDir    = "$pgExtractTo\pgsql\data"
$pgLogsDir    = "$pgExtractTo\pgsql\logs"
$pgZipUrl     = "https://get.enterprisedb.com/postgresql/postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZip        = "$dlDir\postgresql-$pgBuild-windows-x64-binaries.zip"

# Neo4j  – zip contains neo4j-community-2025.11.2\
$neo4jExtract = "$userRoot\neo4j-community-$neo4jVersion-windows"
$neo4jHome    = "$neo4jExtract\neo4j-community-$neo4jVersion"
$neo4jZipUrl  = "https://dist.neo4j.org/neo4j-community-$neo4jVersion-windows.zip"
$neo4jZip     = "$dlDir\neo4j-community-$neo4jVersion-windows.zip"

# Node.js  – zip contains node-v24.13.0-win-x64\
$nodeExtract  = "$userRoot\AppData\Local\Programs\node-v$nodeVersion-win-x64"
$nodeBinDir   = "$nodeExtract\node-v$nodeVersion-win-x64"
$nodeZipUrl   = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip"
$nodeZip      = "$dlDir\node-v$nodeVersion-win-x64.zip"

# ─── HELPERS ──────────────────────────────────────────────────────────────────
function Get-File {
    param([string]$Url, [string]$Dest, [string]$Label)
    if (Test-Path $Dest) {
        Write-Host "  [skip] $Label already in Downloads." -ForegroundColor DarkGray
        return
    }
    Write-Host "  Downloading $Label ..." -ForegroundColor Yellow
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($Url, $Dest)
        Write-Host "  OK  $Dest" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Manual download URL: $Url" -ForegroundColor Cyan
    }
}

function Expand-Zip {
    param([string]$Zip, [string]$Dest, [string]$Label)
    if (Test-Path $Dest) {
        $items = Get-ChildItem $Dest -ErrorAction SilentlyContinue
        if ($items.Count -gt 0) {
            Write-Host "  [skip] $Label already extracted." -ForegroundColor DarkGray
            return
        }
    }
    Write-Host "  Extracting $Label ..." -ForegroundColor Yellow
    New-Item $Dest -ItemType Directory -Force | Out-Null
    Expand-Archive -Path $Zip -DestinationPath $Dest -Force
    Write-Host "  OK  $Dest" -ForegroundColor Green
}

function Add-ToUserPath {
    param([string]$Dir)
    $cur = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($cur -notlike "*$Dir*") {
        [Environment]::SetEnvironmentVariable("Path", "$cur;$Dir", "User")
        Write-Host "  PATH += $Dir" -ForegroundColor Cyan
    } else {
        Write-Host "  [skip] Already in PATH: $Dir" -ForegroundColor DarkGray
    }
}

# ─── STEP 1 · Create directories ──────────────────────────────────────────────
Write-Host "[1/6] Creating directories ..." -ForegroundColor Cyan
foreach ($d in @($dlDir, $pgExtractTo, $neo4jExtract, $nodeExtract, "$userRoot\.local\bin")) {
    New-Item $d -ItemType Directory -Force | Out-Null
}

# ─── STEP 2 · Download zips ───────────────────────────────────────────────────
Write-Host "`n[2/6] Downloading packages ..." -ForegroundColor Cyan
Get-File -Url $pgZipUrl    -Dest $pgZip    -Label "PostgreSQL $pgBuild"
Get-File -Url $neo4jZipUrl -Dest $neo4jZip -Label "Neo4j $neo4jVersion"
Get-File -Url $nodeZipUrl  -Dest $nodeZip  -Label "Node.js v$nodeVersion"

# ─── STEP 3 · Extract zips ────────────────────────────────────────────────────
Write-Host "`n[3/6] Extracting packages ..." -ForegroundColor Cyan
if (Test-Path $pgZip)    { Expand-Zip -Zip $pgZip    -Dest $pgExtractTo  -Label "PostgreSQL" }
if (Test-Path $neo4jZip) { Expand-Zip -Zip $neo4jZip -Dest $neo4jExtract -Label "Neo4j" }
if (Test-Path $nodeZip)  { Expand-Zip -Zip $nodeZip  -Dest $nodeExtract  -Label "Node.js" }

# ─── STEP 4 · Initialize PostgreSQL data directory ────────────────────────────
Write-Host "`n[4/6] Initializing PostgreSQL ..." -ForegroundColor Cyan
if (Test-Path "$pgDataDir\PG_VERSION") {
    Write-Host "  [skip] Data directory already initialized." -ForegroundColor DarkGray
} else {
    $initdb = "$pgBinDir\initdb.exe"
    if (Test-Path $initdb) {
        New-Item $pgDataDir -ItemType Directory -Force | Out-Null
        New-Item $pgLogsDir -ItemType Directory -Force | Out-Null
        & $initdb -D $pgDataDir -U postgres -E UTF8 --locale=en_US.UTF-8
        Write-Host "  PostgreSQL data dir ready: $pgDataDir" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: initdb.exe not found – extraction may have failed." -ForegroundColor Red
        Write-Host "  Expected: $initdb" -ForegroundColor DarkGray
    }
}

# ─── STEP 5 · Persist environment variables ───────────────────────────────────
Write-Host "`n[5/6] Setting user environment variables ..." -ForegroundColor Cyan

[Environment]::SetEnvironmentVariable("NEO4J_HOME", $neo4jHome, "User")
Write-Host "  NEO4J_HOME = $neo4jHome" -ForegroundColor Green

Add-ToUserPath -Dir $pgBinDir
Add-ToUserPath -Dir "$neo4jHome\bin"
Add-ToUserPath -Dir $nodeBinDir
Add-ToUserPath -Dir "$userRoot\.local\bin"

# ─── STEP 6 · Java check (Neo4j 2025.x needs Java 21+) ───────────────────────
Write-Host "`n[6/6] Checking Java ..." -ForegroundColor Cyan
$javaOk = $false
try {
    $jv = & java -version 2>&1 | Select-String "version"
    if ($jv) {
        Write-Host "  Java found: $jv" -ForegroundColor Green
        $javaOk = $true
    }
} catch {}

if (-not $javaOk) {
    Write-Host "  Java NOT found. Neo4j 2025.x requires Java 21+." -ForegroundColor Red
    Write-Host "  Download Java 21 (zip, no installer):" -ForegroundColor Yellow
    Write-Host "  https://github.com/adoptium/temurin21-binaries/releases/latest" -ForegroundColor Cyan
    Write-Host "  Choose: OpenJDK21U-jdk_x64_windows_hotspot_21.x.x.zip" -ForegroundColor Yellow
    Write-Host "  Extract to: $userRoot\java21" -ForegroundColor Yellow
    Write-Host '  Then run: Add-ToUserPath "$userRoot\java21\jdk-21.x.x+x\bin"' -ForegroundColor Yellow
    Write-Host "  Or re-run this script after adding Java to PATH." -ForegroundColor Yellow
}

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  PostgreSQL  $pgBuild   → $pgBinDir" -ForegroundColor White
Write-Host "  Neo4j       $neo4jVersion → $neo4jHome\bin" -ForegroundColor White
Write-Host "  Node.js     v$nodeVersion  → $nodeBinDir" -ForegroundColor White
Write-Host "`n  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell (PATH is now updated)" -ForegroundColor Yellow
Write-Host "  2. Dot-source the control script:" -ForegroundColor Yellow
Write-Host "       . .\microsoft.powershell.ps1" -ForegroundColor White
Write-Host "  3. Use the commands:" -ForegroundColor Yellow
Write-Host "       Start-Postgres   /  Stop-Postgres" -ForegroundColor White
Write-Host "       Start-Neo4j      /  Stop-Neo4j" -ForegroundColor White
Write-Host "       psql -U postgres" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Green
