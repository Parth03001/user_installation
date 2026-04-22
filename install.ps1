# =============================================================
# USER INSTALLATION SCRIPT  (No Admin Required)
# User : 50017162
# Tools: PostgreSQL 18.3 | Neo4j 2025.11.0 | Node.js 24.13.0
#        OpenSearch 3.6.0 | nginx 1.30.0
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
#
#  4. OpenSearch 3.6.0 (direct zip):
#     https://artifacts.opensearch.org/releases/bundle/opensearch/3.6.0/opensearch-3.6.0-windows-x64.zip
#     Save as: opensearch-3.6.0-windows-x64.zip
#
#  5. nginx 1.30.0 (direct zip):
#     https://nginx.org/download/nginx-1.30.0.zip
#     Save as: nginx-1.30.0.zip
#
#  Put ALL zip files in:
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
Write-Host " OpenSearch 3.6.0 | nginx 1.30.0" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkGray
Write-Host ""

# -------------------------------------------------------------
# VERSION CONFIG
# -------------------------------------------------------------
$pgBuild        = "18.3-3"
$neo4jVersion   = "2025.11.0"
$nodeVersion    = "24.13.0"
$osVersion      = "3.6.0"
$nginxVersion   = "1.30.0"

# -------------------------------------------------------------
# PATHS (must match microsoft.powershell.ps1)
# -------------------------------------------------------------
$userRoot    = "C:\Users\50017162"
$dlDir       = "$userRoot\Downloads\_installs"

# PostgreSQL
$pgExtractTo = "$userRoot\PostgreSQL\pgsql"
$pgBinDir    = "$pgExtractTo\pgsql\bin"
$pgDataDir   = "$pgExtractTo\pgsql\data"
$pgLogsDir   = "$pgExtractTo\pgsql\logs"
$pgZipUrl    = "https://get.enterprisedb.com/postgresql/postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZipName   = "postgresql-$pgBuild-windows-x64-binaries.zip"
$pgZip       = "$dlDir\$pgZipName"

# Neo4j
$neo4jExtract = "$userRoot\neo4j-community-$neo4jVersion-windows"
$neo4jHome    = "$neo4jExtract\neo4j-community-$neo4jVersion"
$neo4jZipUrl  = "https://dist.neo4j.org/neo4j-community-$neo4jVersion-windows.zip"
$neo4jZipName = "neo4j-community-$neo4jVersion-windows.zip"
$neo4jZip     = "$dlDir\$neo4jZipName"

# Node.js
$nodeExtract  = "$userRoot\AppData\Local\Programs\node-v$nodeVersion-win-x64"
$nodeBinDir   = "$nodeExtract\node-v$nodeVersion-win-x64"
$nodeZipUrl   = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip"
$nodeZipName  = "node-v$nodeVersion-win-x64.zip"
$nodeZip      = "$dlDir\$nodeZipName"

# OpenSearch  -- zip extracts to opensearch-3.6.0\ inside
$osExtractTo  = "$userRoot\opensearch"
$osHome       = "$osExtractTo\opensearch-$osVersion"
$osZipUrl     = "https://artifacts.opensearch.org/releases/bundle/opensearch/$osVersion/opensearch-$osVersion-windows-x64.zip"
$osZipName    = "opensearch-$osVersion-windows-x64.zip"
$osZip        = "$dlDir\$osZipName"
# Also accept the user's filename variant (window vs windows)
$osZipAlt     = "$dlDir\opensearch-$osVersion-window-x64.zip"

# nginx  -- zip extracts to nginx-1.30.0\ inside
$nginxExtractTo = "$userRoot\nginx"
$nginxHome      = "$nginxExtractTo\nginx-$nginxVersion"
$nginxZipUrl    = "https://nginx.org/download/nginx-$nginxVersion.zip"
$nginxZipName   = "nginx-$nginxVersion.zip"
$nginxZip       = "$dlDir\$nginxZipName"

# -------------------------------------------------------------
# HELPERS
# -------------------------------------------------------------
function Get-ZipFile {
    param([string]$Url, [string]$Dest, [string]$Label, [string]$ManualPage)
    if (Test-Path $Dest) {
        Write-Host "  [found] $Label zip in Downloads folder." -ForegroundColor Green
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
        Write-Host "    Manual URL : $ManualPage" -ForegroundColor Cyan
        Write-Host "    Save to    : $Dest" -ForegroundColor Cyan
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

function Write-ConfigFile {
    param([string]$Path, [string]$Content, [string]$Label)
    New-Item (Split-Path $Path) -ItemType Directory -Force | Out-Null
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "  Config written: $Label" -ForegroundColor Green
}

# -------------------------------------------------------------
# STEP 1 - Create directories
# -------------------------------------------------------------
Write-Host "[1/8] Creating directories ..." -ForegroundColor Cyan
foreach ($d in @($dlDir, $pgExtractTo, $neo4jExtract, $nodeExtract, $osExtractTo, $nginxExtractTo, "$userRoot\.local\bin")) {
    New-Item $d -ItemType Directory -Force | Out-Null
}
Write-Host "  Done." -ForegroundColor Green

# -------------------------------------------------------------
# STEP 2 - Download / verify zips
# -------------------------------------------------------------
Write-Host ""
Write-Host "[2/8] Checking / downloading packages ..." -ForegroundColor Cyan

Get-ZipFile -Url $nodeZipUrl -Dest $nodeZip -Label "Node.js v$nodeVersion" `
    -ManualPage "https://nodejs.org/dist/v$nodeVersion/$nodeZipName"

Get-ZipFile -Url $neo4jZipUrl -Dest $neo4jZip -Label "Neo4j $neo4jVersion" `
    -ManualPage "https://neo4j.com/deployment-center/"

Get-ZipFile -Url $pgZipUrl -Dest $pgZip -Label "PostgreSQL $pgBuild" `
    -ManualPage "https://www.enterprisedb.com/download-postgresql-binaries"

# OpenSearch: accept either windows or window filename
if (Test-Path $osZipAlt) {
    Write-Host "  [found] OpenSearch zip (window variant) in Downloads folder." -ForegroundColor Green
    $osZip = $osZipAlt
}
else {
    Get-ZipFile -Url $osZipUrl -Dest $osZip -Label "OpenSearch $osVersion" `
        -ManualPage "https://opensearch.org/downloads.html"
}

Get-ZipFile -Url $nginxZipUrl -Dest $nginxZip -Label "nginx $nginxVersion" `
    -ManualPage "https://nginx.org/en/download.html"

# -------------------------------------------------------------
# STEP 3 - Extract zips
# -------------------------------------------------------------
Write-Host ""
Write-Host "[3/8] Extracting packages ..." -ForegroundColor Cyan

if (Test-Path $nodeZip)  { Expand-ZipFile -ZipPath $nodeZip  -DestDir $nodeExtract  -Label "Node.js" }
else { Write-Host "  [skip] Node.js zip not found." -ForegroundColor Red }

if (Test-Path $neo4jZip) { Expand-ZipFile -ZipPath $neo4jZip -DestDir $neo4jExtract -Label "Neo4j" }
else { Write-Host "  [skip] Neo4j zip not found." -ForegroundColor Red }

if (Test-Path $pgZip)    { Expand-ZipFile -ZipPath $pgZip    -DestDir $pgExtractTo  -Label "PostgreSQL" }
else { Write-Host "  [skip] PostgreSQL zip not found." -ForegroundColor Red }

if (Test-Path $osZip)    { Expand-ZipFile -ZipPath $osZip    -DestDir $osExtractTo  -Label "OpenSearch" }
else { Write-Host "  [skip] OpenSearch zip not found." -ForegroundColor Red }

if (Test-Path $nginxZip) { Expand-ZipFile -ZipPath $nginxZip -DestDir $nginxExtractTo -Label "nginx" }
else { Write-Host "  [skip] nginx zip not found." -ForegroundColor Red }

# -------------------------------------------------------------
# STEP 4 - Initialize PostgreSQL data directory
# -------------------------------------------------------------
Write-Host ""
Write-Host "[4/8] Initializing PostgreSQL ..." -ForegroundColor Cyan
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
# STEP 5 - Configure OpenSearch
# -------------------------------------------------------------
Write-Host ""
Write-Host "[5/8] Configuring OpenSearch ..." -ForegroundColor Cyan
$osConfigPath = "$osHome\config\opensearch.yml"
if (Test-Path $osHome) {
    $osDataDir = "$osHome\data"
    $osLogsDir = "$osHome\logs"
    New-Item $osDataDir -ItemType Directory -Force | Out-Null
    New-Item $osLogsDir -ItemType Directory -Force | Out-Null

    # Use forward slashes in the yml (cross-platform safe)
    $osDataYml = $osDataDir.Replace("\", "/")
    $osLogsYml = $osLogsDir.Replace("\", "/")

    $osConfig = @"
# OpenSearch 3.6.0 - single-node dev config
cluster.name: local-cluster
node.name: local-node

path.data: $osDataYml
path.logs: $osLogsYml

network.host: 127.0.0.1
http.port: 9200

discovery.type: single_node

# Disable security plugin for local development
plugins.security.disabled: true
"@
    Write-ConfigFile -Path $osConfigPath -Content $osConfig -Label "opensearch.yml"
    Write-Host "  OpenSearch port : 9200 (HTTP, security disabled for dev)" -ForegroundColor DarkGray
}
else {
    Write-Host "  [skip] OpenSearch not yet extracted. Config will apply on next run." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# STEP 6 - Configure nginx
# -------------------------------------------------------------
Write-Host ""
Write-Host "[6/8] Configuring nginx ..." -ForegroundColor Cyan
$nginxConfigPath = "$nginxHome\conf\nginx.conf"
if (Test-Path $nginxHome) {
    $nginxLogsDir = "$nginxHome\logs"
    New-Item $nginxLogsDir -ItemType Directory -Force | Out-Null

    $nginxConfig = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout  65;

    server {
        listen       8080;
        server_name  localhost;

        # OpenSearch REST API
        location /opensearch/ {
            proxy_pass         http://127.0.0.1:9200/;
            proxy_set_header   Host \$host;
            proxy_set_header   X-Real-IP \$remote_addr;
        }

        # Neo4j Browser UI
        location /neo4j/ {
            proxy_pass         http://127.0.0.1:7474/;
            proxy_set_header   Host \$host;
            proxy_http_version 1.1;
            proxy_set_header   Upgrade \$http_upgrade;
            proxy_set_header   Connection "upgrade";
        }

        # Default - static files
        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
"@
    Write-ConfigFile -Path $nginxConfigPath -Content $nginxConfig -Label "nginx.conf"
    Write-Host "  nginx port      : 8080 (no admin needed)" -ForegroundColor DarkGray
    Write-Host "  /opensearch/    -> proxies to OpenSearch :9200" -ForegroundColor DarkGray
    Write-Host "  /neo4j/         -> proxies to Neo4j browser :7474" -ForegroundColor DarkGray
}
else {
    Write-Host "  [skip] nginx not yet extracted. Config will apply on next run." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# STEP 7 - Set user environment variables
# -------------------------------------------------------------
Write-Host ""
Write-Host "[7/8] Setting user environment variables ..." -ForegroundColor Cyan

[Environment]::SetEnvironmentVariable("NEO4J_HOME",       $neo4jHome, "User")
[Environment]::SetEnvironmentVariable("OPENSEARCH_HOME",  $osHome,    "User")
Write-Host "  NEO4J_HOME      = $neo4jHome" -ForegroundColor Green
Write-Host "  OPENSEARCH_HOME = $osHome" -ForegroundColor Green

Add-ToUserPath -Dir $pgBinDir
Add-ToUserPath -Dir "$neo4jHome\bin"
Add-ToUserPath -Dir $nodeBinDir
Add-ToUserPath -Dir "$osHome\bin"
Add-ToUserPath -Dir $nginxHome
Add-ToUserPath -Dir "$userRoot\.local\bin"

# -------------------------------------------------------------
# STEP 8 - Java check (Neo4j + OpenSearch both need Java 21+)
# -------------------------------------------------------------
Write-Host ""
Write-Host "[8/8] Checking Java ..." -ForegroundColor Cyan
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
    Write-Host "  Java NOT found. Neo4j and OpenSearch both require Java 21+." -ForegroundColor Red
    Write-Host "  Download Java 21 zip (no installer, no admin):" -ForegroundColor Yellow
    Write-Host "    https://adoptium.net/temurin/releases/?version=21&os=windows&arch=x64&package_type=zip" -ForegroundColor Cyan
    Write-Host "  Extract to : $userRoot\java21" -ForegroundColor Yellow
    Write-Host "  Then add   : $userRoot\java21\jdk-21.x.x\bin  to user PATH" -ForegroundColor Yellow
}

# -------------------------------------------------------------
# SUMMARY
# -------------------------------------------------------------
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  PostgreSQL  v$pgBuild   -> $pgBinDir" -ForegroundColor White
Write-Host "  Neo4j       $neo4jVersion   -> $neo4jHome\bin" -ForegroundColor White
Write-Host "  Node.js     v$nodeVersion    -> $nodeBinDir" -ForegroundColor White
Write-Host "  OpenSearch  v$osVersion    -> $osHome\bin" -ForegroundColor White
Write-Host "  nginx       v$nginxVersion  -> $nginxHome" -ForegroundColor White
Write-Host ""
Write-Host "  PORTS:" -ForegroundColor Cyan
Write-Host "    PostgreSQL  : 5432" -ForegroundColor White
Write-Host "    Neo4j HTTP  : 7474  (browser UI)" -ForegroundColor White
Write-Host "    Neo4j Bolt  : 7687" -ForegroundColor White
Write-Host "    OpenSearch  : 9200" -ForegroundColor White
Write-Host "    nginx       : 8080  (reverse proxy)" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell" -ForegroundColor Yellow
Write-Host "  2. Run: . .\microsoft.powershell.ps1" -ForegroundColor White
Write-Host "  3. Then start services individually:" -ForegroundColor Yellow
Write-Host "     Start-Postgres / Start-Neo4j / Start-OpenSearch / Start-Nginx" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Green
