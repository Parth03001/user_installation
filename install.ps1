# =============================================================
# USER INSTALLATION SCRIPT  (No Admin Required)
# User : 50017162
# Tools: PostgreSQL 18.3 | Neo4j 2025.11.0 | Node.js 24.13.0
#
# =============================================================
# MANUAL DOWNLOAD LINKS
# =============================================================
#
#  1. Node.js v24.13.0 (direct zip, 36 MB):
#     https://nodejs.org/dist/v24.13.0/node-v24.13.0-win-x64.zip
#     Save as: node-v24.13.0-win-x64.zip
#
#  2. Neo4j Community 2025.11.0 (direct zip):
#     https://dist.neo4j.org/neo4j-community-2025.11.0-windows.zip
#     Save as: neo4j-community-2025.11.0-windows.zip
#
#  3. PostgreSQL 18 binaries zip (~330 MB):
#     Visit: https://www.enterprisedb.com/download-postgresql-binaries
#     Click the Windows x86-64 download button for PostgreSQL 18
#     Save as: postgresql-18.3-3-windows-x64-binaries.zip
#     (rename the file to match this exact name)
#
#  Put all 3 zip files in:
#     C:\Users\50017162\Downloads\_installs\
#  Then run this script.
#
# =============================================================

if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Write-Host ""
Write-Host " AI/ML Stack Installer - user 50017162 (no admin)" -ForegroundColor Green
Write-Host " PostgreSQL 18.3 | Neo4j 2025.11.0 | Node.js v24.13.0" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkGray
Write-Host ""

# -------------------------------------------------------------
# VERSION CONFIG
# -------------------------------------------------------------
$pgBuild      = "18.3-3"
$neo4jVersion = "2025.11.0"
$nodeVersion  = "24.13.0"

# -------------------------------------------------------------
# PATHS (must match microsoft.powershell.ps1)
# -------------------------------------------------------------
$userRoot    = "C:\Users\50017162"
$dlDir       = "$userRoot\Downloads\_installs"

$pgExtractTo = "$userRoot\PostgreSQL\pgsql"
$pgBinDir    = "$pgExtractTo\pgsql\bin"
$pgDataDir   = "$pgExtractTo\pgsql\data"
$pgLogsDir   = "$pgExtractTo\pgsql\logs"
$pgZipUrl    = "https://get.enterprisedb.com/postgresql/postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZipName   = "postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZip       = "$dlDir\$pgZipName"

$neo4jExtract = "$userRoot\neo4j-community-$neo4jVersion-windows"
$neo4jHome    = "$neo4jExtract\neo4j-community-$neo4jVersion"
$neo4jZipUrl  = "https://dist.neo4j.org/neo4j-community-$neo4jVersion-windows.zip"
$neo4jZipName = "neo4j-community-$neo4jVersion-windows.zip"
$neo4jZip     = "$dlDir\$neo4jZipName"

$nodeExtract  = "$userRoot\AppData\Local\Programs\node-v$nodeVersion-win-x64"
$nodeBinDir   = "$nodeExtract\node-v$nodeVersion-win-x64"
$nodeZipUrl   = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip"
$nodeZipName  = "node-v$nodeVersion-win-x64.zip"
$nodeZip      = "$dlDir\$nodeZipName"

# -------------------------------------------------------------
# HELPERS
# -------------------------------------------------------------
function Get-ZipFile {
    param([string]$Url, [string]$Dest, [string]$Label, [string]$ManualPage)
    if (Test-Path $Dest) {
        Write-Host "  [found] $Label zip already in Downloads folder." -ForegroundColor Green
        return
    }
    Write-Host "  Trying auto-download: $Label ..." -ForegroundColor Yellow
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($Url, $Dest)
        Write-Host "  OK -> $Dest" -ForegroundColor Green
    }
    catch {
        Write-Host "  Auto-download failed for $Label." -ForegroundColor Red
        Write-Host "  MANUAL DOWNLOAD REQUIRED:" -ForegroundColor Yellow
        Write-Host "    URL : $ManualPage" -ForegroundColor Cyan
        Write-Host "    Save to: $Dest" -ForegroundColor Cyan
        Write-Host "    Then re-run this script." -ForegroundColor Yellow
    }
}

function Expand-ZipFile {
    param([string]$ZipPath, [string]$DestDir, [string]$Label)
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
New-Item $dlDir        -ItemType Directory -Force | Out-Null
New-Item $pgExtractTo  -ItemType Directory -Force | Out-Null
New-Item $neo4jExtract -ItemType Directory -Force | Out-Null
New-Item $nodeExtract  -ItemType Directory -Force | Out-Null
New-Item "$userRoot\.local\bin" -ItemType Directory -Force | Out-Null
Write-Host "  Done." -ForegroundColor Green

# -------------------------------------------------------------
# STEP 2 - Download / verify zips
# -------------------------------------------------------------
Write-Host ""
Write-Host "[2/6] Checking / downloading packages ..." -ForegroundColor Cyan
Get-ZipFile -Url $nodeZipUrl -Dest $nodeZip -Label "Node.js v$nodeVersion" `
    -ManualPage "https://nodejs.org/dist/v$nodeVersion/$nodeZipName"

Get-ZipFile -Url $neo4jZipUrl -Dest $neo4jZip -Label "Neo4j $neo4jVersion" `
    -ManualPage "https://neo4j.com/deployment-center/"

Get-ZipFile -Url $pgZipUrl -Dest $pgZip -Label "PostgreSQL $pgBuild" `
    -ManualPage "https://www.enterprisedb.com/download-postgresql-binaries"

# -------------------------------------------------------------
# STEP 3 - Extract zips (only if zip exists)
# -------------------------------------------------------------
Write-Host ""
Write-Host "[3/6] Extracting packages ..." -ForegroundColor Cyan
if (Test-Path $nodeZip)  { Expand-ZipFile -ZipPath $nodeZip  -DestDir $nodeExtract  -Label "Node.js" }
else { Write-Host "  [skip] Node.js zip not found - download it first." -ForegroundColor Red }

if (Test-Path $neo4jZip) { Expand-ZipFile -ZipPath $neo4jZip -DestDir $neo4jExtract -Label "Neo4j" }
else { Write-Host "  [skip] Neo4j zip not found - download it first." -ForegroundColor Red }

if (Test-Path $pgZip)    { Expand-ZipFile -ZipPath $pgZip    -DestDir $pgExtractTo  -Label "PostgreSQL" }
else { Write-Host "  [skip] PostgreSQL zip not found - download it first." -ForegroundColor Red }

# -------------------------------------------------------------
# STEP 4 - Initialize PostgreSQL data directory
# -------------------------------------------------------------
Write-Host ""
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
        Write-Host "  WARNING: initdb.exe not found. PostgreSQL not yet extracted." -ForegroundColor Red
    }
}

# -------------------------------------------------------------
# STEP 5 - Set user environment variables
# -------------------------------------------------------------
Write-Host ""
Write-Host "[5/6] Setting user environment variables ..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("NEO4J_HOME", $neo4jHome, "User")
Write-Host "  NEO4J_HOME = $neo4jHome" -ForegroundColor Green
Add-ToUserPath -Dir $pgBinDir
Add-ToUserPath -Dir "$neo4jHome\bin"
Add-ToUserPath -Dir $nodeBinDir
Add-ToUserPath -Dir "$userRoot\.local\bin"

# -------------------------------------------------------------
# STEP 6 - Java check (Neo4j requires Java 21+)
# -------------------------------------------------------------
Write-Host ""
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
    Write-Host "  Download Java 21 zip (no installer, no admin):" -ForegroundColor Yellow
    Write-Host "    https://adoptium.net/temurin/releases/?version=21&os=windows&arch=x64&package_type=zip" -ForegroundColor Cyan
    Write-Host "  Extract to: $userRoot\java21" -ForegroundColor Yellow
    Write-Host "  Then add $userRoot\java21\jdk-21.x.x\bin to your user PATH." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# SUMMARY
# -------------------------------------------------------------
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  DONE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  PostgreSQL  v$pgBuild  -> $pgBinDir" -ForegroundColor White
Write-Host "  Neo4j       $neo4jVersion -> $neo4jHome\bin" -ForegroundColor White
Write-Host "  Node.js     v$nodeVersion  -> $nodeBinDir" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell" -ForegroundColor Yellow
Write-Host "  2. Run: . .\microsoft.powershell.ps1" -ForegroundColor White
Write-Host "  3. Then: Start-Postgres  or  Start-Neo4j" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Green
