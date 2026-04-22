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
$javaVersion  = "21.0.10"
$javaBuild    = "7"

# ENV VARS
$env:JAVA_HOME       = "C:\Users\50017162\java21\jdk-$javaVersion+$javaBuild"
$env:NEO4J_HOME      = "C:\Users\50017162\neo4j-community-$neo4jVersion-windows\neo4j-community-$neo4jVersion"
$env:OPENSEARCH_HOME = "C:\Users\50017162\opensearch\opensearch-$osVersion"

# SESSION PATH (adds to current shell only)
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
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

function Set-PostgresPassword {
    param(
        [string]$NewPassword = ""
    )
    Write-Host ""
    Write-Host "=== Change PostgreSQL password for user 'postgres' ===" -ForegroundColor Cyan
    if ($NewPassword -eq "") {
        $secure = Read-Host "Enter new password for postgres" -AsSecureString
        $NewPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        )
    }
    $sql = "ALTER USER postgres WITH PASSWORD '$NewPassword';"
    & "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin\psql.exe" -U postgres -h localhost -c $sql
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Password changed successfully." -ForegroundColor Green
        Write-Host "From now on connect with: psql -U postgres -h localhost -W" -ForegroundColor Yellow
    }
    else {
        Write-Host "Failed. Make sure Postgres is running: Start-Postgres" -ForegroundColor Red
    }
}

function Connect-Postgres {
    Write-Host "Connecting to PostgreSQL as postgres ..." -ForegroundColor Cyan
    & "C:\Users\50017162\PostgreSQL\pgsql\pgsql\bin\psql.exe" -U postgres -h localhost
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
    Write-Host "  Credentials: admin / Dataeaze@12345" -ForegroundColor DarkGray
    $opensearchBat = "$env:OPENSEARCH_HOME\bin\opensearch.bat"
    if (-not (Test-Path $opensearchBat)) {
        Write-Host "ERROR: opensearch.bat not found at $opensearchBat" -ForegroundColor Red
        return
    }
    Set-Location $env:OPENSEARCH_HOME
    $env:OPENSEARCH_JAVA_OPTS = "-Xms512m -Xmx512m"
    # Password set on first boot via OPENSEARCH_INITIAL_ADMIN_PASSWORD (OpenSearch 2.12+)
    $env:OPENSEARCH_INITIAL_ADMIN_PASSWORD = "Dataeaze@12345"
    & $opensearchBat
}

function Reset-OpenSearchData {
    Write-Host "Deleting OpenSearch data directory for fresh security init ..." -ForegroundColor Yellow
    $dataDir = "$env:OPENSEARCH_HOME\data"
    if (Test-Path $dataDir) {
        Remove-Item -Recurse -Force $dataDir
        Write-Host "  Deleted: $dataDir" -ForegroundColor Green
        Write-Host "  Start OpenSearch again - it will reinitialise with password Dataeaze@12345" -ForegroundColor Cyan
    }
    else {
        Write-Host "  Data directory not found (already clean)." -ForegroundColor DarkGray
    }
}

function Fix-OpenSearchConfig {
    Write-Host ""
    Write-Host "=== Fix-OpenSearchConfig ===" -ForegroundColor Cyan
    $osHome   = $env:OPENSEARCH_HOME
    $confDir  = "$osHome\config"
    $certDir  = $confDir.Replace("\", "/")

    # 1. Find any PEM files anywhere under opensearch dir
    Write-Host "Searching for PEM certificate files ..." -ForegroundColor Yellow
    $allPems = Get-ChildItem $osHome -Recurse -Filter "*.pem" -ErrorAction SilentlyContinue
    if ($allPems) {
        $allPems | ForEach-Object { Write-Host "  Found: $($_.FullName)" -ForegroundColor Green }
    }
    else {
        Write-Host "  No .pem files found yet - will run demo cert generator." -ForegroundColor Red
    }

    # 2. Run the demo cert generator if root-ca.pem is still missing in config/
    $rootCa = "$confDir\root-ca.pem"
    if (-not (Test-Path $rootCa)) {
        $demoScript = "$osHome\plugins\opensearch-security\tools\install_demo_configuration.bat"
        if (Test-Path $demoScript) {
            Write-Host "Running install_demo_configuration.bat -y ..." -ForegroundColor Yellow
            $env:OPENSEARCH_HOME = $osHome
            Push-Location $osHome
            $out = & cmd.exe /c "`"$demoScript`" -y 2>&1"
            Pop-Location
            $out | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        }
        else {
            Write-Host "  ERROR: demo script not found: $demoScript" -ForegroundColor Red
        }
    }

    # 3. Re-check and report
    Write-Host ""
    Write-Host "Certificate status in $confDir :" -ForegroundColor Cyan
    foreach ($f in @("root-ca.pem","esnode.pem","esnode-key.pem","kirk.pem","kirk-key.pem")) {
        $fp = "$confDir\$f"
        if (Test-Path $fp) {
            Write-Host "  [OK]      $f" -ForegroundColor Green
        }
        else {
            Write-Host "  [MISSING] $f" -ForegroundColor Red
        }
    }

    # 4. Rewrite opensearch.yml with absolute paths so OpenSearch can always find the certs
    if (Test-Path "$confDir\root-ca.pem") {
        $osDataYml = "$osHome\data".Replace("\", "/")
        $osLogsYml = "$osHome\logs".Replace("\", "/")

        $osConfig = @"
# OpenSearch $osVersion - single-node  admin / Dataeaze@12345
cluster.name: local-cluster
node.name: local-node

path.data: $osDataYml
path.logs: $osLogsYml

network.host: 127.0.0.1
http.port: 9200

cluster.initial_cluster_manager_nodes: local-node
discovery.seed_hosts: []

plugins.security.ssl.http.enabled: false
plugins.security.ssl.transport.pemcert_filepath: $certDir/esnode.pem
plugins.security.ssl.transport.pemkey_filepath: $certDir/esnode-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: $certDir/root-ca.pem
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.allow_unsafe_democertificates: true
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=kirk,OU=client,O=client,L=test,C=de"
plugins.security.nodes_dn:
  - "CN=localhost,OU=node,O=node,L=test,C=de"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText("$confDir\opensearch.yml", $osConfig, $utf8NoBom)
        Write-Host ""
        Write-Host "  opensearch.yml rewritten with absolute cert paths." -ForegroundColor Green
        Write-Host "  Now run: Reset-OpenSearchData  (clears old data)" -ForegroundColor Yellow
        Write-Host "  Then  : Start-OpenSearch" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "  Certificates still missing. Cannot fix opensearch.yml." -ForegroundColor Red
        Write-Host "  Manual steps:" -ForegroundColor Yellow
        Write-Host "    1. cd $osHome" -ForegroundColor White
        Write-Host "    2. .\plugins\opensearch-security\tools\install_demo_configuration.bat" -ForegroundColor White
        Write-Host "    3. Run Fix-OpenSearchConfig again" -ForegroundColor White
    }
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
        $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:Dataeaze@12345"))
        $headers = @{ Authorization = "Basic $cred" }
        $r = Invoke-RestMethod -Uri "http://localhost:9200" -Method Get -Headers $headers -TimeoutSec 3
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
Write-Host "  Start-OpenSearch   /  Stop-OpenSearch   (port 9200  admin/Dataeaze@12345)" -ForegroundColor Yellow
Write-Host "  Reset-OpenSearchData  <- wipe data for fresh security init" -ForegroundColor Yellow
Write-Host "  Fix-OpenSearchConfig  <- fix cert paths if OpenSearch won't start" -ForegroundColor Yellow
Write-Host "  Start-Nginx        /  Stop-Nginx        (port 8080)" -ForegroundColor Yellow
Write-Host "  Reload-Nginx       /  Get-OpenSearchStatus" -ForegroundColor Yellow
Write-Host "  Start-All          /  Stop-All" -ForegroundColor Yellow
Write-Host "  Connect-Postgres   /  Set-PostgresPassword" -ForegroundColor Yellow
Write-Host ""

# Quick status check (java -version writes to stderr, convert to string first)
try { java -version 2>&1 | ForEach-Object { $_.ToString() } | Select-Object -First 1 } catch {}
try { pg_isready -h localhost -p 5432 2>&1 | ForEach-Object { $_.ToString() } | Select-Object -First 1 } catch {}
try { node --version } catch {}
