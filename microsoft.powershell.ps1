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
    $osHome    = $env:OPENSEARCH_HOME
    $confDir   = "$osHome\config"
    $ksPath    = "$confDir\transport.jks"
    $tsPath    = "$confDir\truststore.jks"
    $crtPath   = "$confDir\transport.crt"
    $ksPass    = "changeit"
    $ksFwd     = $ksPath.Replace("\", "/")
    $tsFwd     = $tsPath.Replace("\", "/")
    $nodeDN    = "CN=localhost,OU=node,O=node,L=test,C=de"

    $keytoolExe = "$env:JAVA_HOME\bin\keytool.exe"
    if (-not (Test-Path $keytoolExe)) {
        Write-Host "  ERROR: keytool.exe not found at $keytoolExe" -ForegroundColor Red
        Write-Host "  Make sure JAVA_HOME is set and Java 21 is installed." -ForegroundColor Yellow
        return
    }

    # Step 1: keystore - private key + self-signed cert (PrivateKeyEntry)
    if (-not (Test-Path $ksPath)) {
        Write-Host "  Step 1/3: Generating keystore (transport.jks) ..." -ForegroundColor Yellow
        & $keytoolExe -genkeypair -alias opensearch `
            -keyalg RSA -keysize 2048 -validity 3650 `
            -keystore $ksPath -storepass $ksPass -keypass $ksPass `
            -dname $nodeDN -storetype JKS -noprompt 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        if (-not (Test-Path $ksPath)) {
            Write-Host "  ERROR: Failed to create transport.jks." -ForegroundColor Red; return
        }
        Write-Host "  transport.jks created." -ForegroundColor Green
    }
    else {
        Write-Host "  [skip] transport.jks already exists." -ForegroundColor DarkGray
    }

    # Step 2: export the self-signed cert as PEM/DER
    if (-not (Test-Path $crtPath)) {
        Write-Host "  Step 2/3: Exporting certificate to transport.crt ..." -ForegroundColor Yellow
        & $keytoolExe -exportcert -alias opensearch `
            -keystore $ksPath -storepass $ksPass `
            -file $crtPath -rfc 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
    else {
        Write-Host "  [skip] transport.crt already exists." -ForegroundColor DarkGray
    }

    # Step 3: truststore - import cert as TrustedCertEntry (what OpenSearch checks)
    # OpenSearch's TrustStoreConfiguration.loadCertificates() only counts TrustedCertEntry
    # records, not PrivateKeyEntry records, so using the same JKS for both fails.
    if (-not (Test-Path $tsPath)) {
        Write-Host "  Step 3/3: Creating truststore (truststore.jks) ..." -ForegroundColor Yellow
        & $keytoolExe -importcert -alias opensearch `
            -keystore $tsPath -storepass $ksPass `
            -file $crtPath -noprompt 2>&1 |
            ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        if (Test-Path $tsPath) {
            Write-Host "  truststore.jks created." -ForegroundColor Green
        }
        else {
            Write-Host "  ERROR: Failed to create truststore.jks." -ForegroundColor Red; return
        }
    }
    else {
        Write-Host "  [skip] truststore.jks already exists." -ForegroundColor DarkGray
    }

    # Write opensearch.yml with separate keystore + truststore paths
    $osDataYml = "$osHome\data".Replace("\", "/")
    $osLogsYml = "$osHome\logs".Replace("\", "/")
    New-Item "$osHome\data" -ItemType Directory -Force | Out-Null
    New-Item "$osHome\logs" -ItemType Directory -Force | Out-Null

    $osConfig = @"
# OpenSearch 3.6.0 - single-node  admin / Dataeaze@12345
cluster.name: local-cluster
node.name: local-node

path.data: $osDataYml
path.logs: $osLogsYml

network.host: 127.0.0.1
http.port: 9200

cluster.initial_cluster_manager_nodes: local-node
discovery.seed_hosts: []

plugins.security.ssl.http.enabled: false
plugins.security.ssl.transport.keystore_type: JKS
plugins.security.ssl.transport.keystore_filepath: transport.jks
plugins.security.ssl.transport.keystore_password: $ksPass
plugins.security.ssl.transport.keystore_keypassword: $ksPass
plugins.security.ssl.transport.truststore_type: JKS
plugins.security.ssl.transport.truststore_filepath: truststore.jks
plugins.security.ssl.transport.truststore_password: $ksPass
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.allow_unsafe_democertificates: true
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "$nodeDN"
plugins.security.nodes_dn:
  - "$nodeDN"
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText("$confDir\opensearch.yml", $osConfig, $utf8NoBom)
    Write-Host "  opensearch.yml rewritten." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "    Reset-OpenSearchData   <- wipe old data (required)" -ForegroundColor Yellow
    Write-Host "    Start-OpenSearch       <- then start" -ForegroundColor Yellow
    Write-Host "  Login: admin / Dataeaze@12345" -ForegroundColor White
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
