@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCAN_BAT=%~f0"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"# __PS1__" "!SCAN_BAT!"') do set /a "PS_START=%%a"
for /f "tokens=1 delims=:" %%a in ('findstr /n /c:"# __ENDPS__" "!SCAN_BAT!"') do set /a "PS_END=%%a-2"
goto :batch

:batch
for %%I in ("!SCAN_BAT!") do cd /d "%%~dpI"
title ac's port scanner v1.0
color 0B

if /i "%~1"=="--ps" shift & goto :invoke
if "%~1"=="" goto :menu
if /i "%~1"=="-h" goto :usage
if /i "%~1"=="--help" goto :usage
if /i "%~1"=="help" goto :usage
if /i "%~1"=="menu" goto :menu
goto :parse

:menu
cls
echo.
echo   ============================================
echo     ac's port scanner v1.0  (files=off)
echo   ============================================
echo.
echo   [1] Quick scan     - top 100 common ports
echo   [2] Web scan       - HTTP/HTTPS and proxies
echo   [3] Dev scan       - SSH, RDP, DB, admin ports
echo   [4] Custom range   - e.g. 1-1024
echo   [5] Custom list    - e.g. 22,80,443
echo   [6] CLI help
echo   [0] Exit
echo.
set "CHOICE="
set /p "CHOICE=  Select [0-6]: "
if "!CHOICE!"=="0" exit /b 0
if "!CHOICE!"=="6" goto :usage
if "!CHOICE!"=="" goto :menu

set "TARGET="
set /p "TARGET=  Target (IP or hostname): "
if "!TARGET!"=="" (
    echo   Target required.
    pause
    goto :menu
)

if "!CHOICE!"=="1" set "PORTS=top100" & goto :invoke_menu
if "!CHOICE!"=="2" set "PORTS=web" & goto :invoke_menu
if "!CHOICE!"=="3" set "PORTS=dev" & goto :invoke_menu
if "!CHOICE!"=="4" (
    set "PORTS="
    set /p "PORTS=  Port range (e.g. 1-1024): "
    if "!PORTS!"=="" set "PORTS=1-1024"
    goto :invoke_menu
)
if "!CHOICE!"=="5" (
    set "PORTS="
    set /p "PORTS=  Port list (e.g. 22,80,443): "
    if "!PORTS!"=="" (
        echo   Port list required.
        pause
        goto :menu
    )
    goto :invoke_menu
)
echo   Invalid choice.
pause
goto :menu

:invoke_menu
set "THREADS=64"
set "TIMEOUT=800"
set "OUTCSV="
set /p "THREADS=  Threads [64]: "
if "!THREADS!"=="" set "THREADS=64"
set /p "TIMEOUT=  Timeout ms [800]: "
if "!TIMEOUT!"=="" set "TIMEOUT=800"
set "TARGET_ARG=!TARGET!"
set "PORTS_ARG=!PORTS!"
goto :invoke

:parse
set "TARGET=%~1"
set "PORTS=top100"
set "THREADS=64"
set "TIMEOUT=800"
set "OUTCSV="
shift

:parse_loop
if "%~1"=="" goto :invoke
if /i "%~1"=="--top100" set "PORTS=top100" & shift & goto :parse_loop
if /i "%~1"=="--top20" set "PORTS=top20" & shift & goto :parse_loop
if /i "%~1"=="--web" set "PORTS=web" & shift & goto :parse_loop
if /i "%~1"=="--dev" set "PORTS=dev" & shift & goto :parse_loop
if /i "%~1"=="top100" set "PORTS=top100" & shift & goto :parse_loop
if /i "%~1"=="top20" set "PORTS=top20" & shift & goto :parse_loop
if /i "%~1"=="web" set "PORTS=web" & shift & goto :parse_loop
if /i "%~1"=="dev" set "PORTS=dev" & shift & goto :parse_loop
if /i "%~1"=="--resolve" set "SCAN_RESOLVE=1" & shift & goto :parse_loop
if /i "%~1"=="--quiet" set "SCAN_QUIET=1" & shift & goto :parse_loop
if /i "%~1"=="--threads" (
    set "THREADS=%~2"
    shift
    shift
    goto :parse_loop
)
if /i "%~1"=="--timeout" (
    set "TIMEOUT=%~2"
    shift
    shift
    goto :parse_loop
)
if /i "%~1"=="--out" (
    set "OUTCSV=%~2"
    shift
    shift
    goto :parse_loop
)
if not defined PORTS_ARG (
    echo "%~1"| findstr /r "^[0-9]" >nul && set "PORTS=%~1" & shift & goto :parse_loop
)
shift
goto :parse_loop

:invoke
if not defined TARGET_ARG set "TARGET_ARG=%TARGET%"
if not defined PORTS_ARG set "PORTS_ARG=%PORTS%"
if not defined SCAN_RESOLVE set "SCAN_RESOLVE=0"
if not defined SCAN_QUIET set "SCAN_QUIET=0"

set "_PS_BAT=!SCAN_BAT!"
set "_PS_TARGET=!TARGET_ARG!"
set "_PS_PORTS=!PORTS_ARG!"
set "_PS_TIMEOUT=!TIMEOUT!"
set "_PS_THREADS=!THREADS!"
set "_PS_OUTCSV=!OUTCSV!"
set "_PS_RESOLVE=!SCAN_RESOLVE!"
set "_PS_QUIET=!SCAN_QUIET!"
set "_PS_START=!PS_START!"
set "_PS_END=!PS_END!"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $all=Get-Content -LiteralPath $env:_PS_BAT; $code=($all[[int]$env:_PS_START..[int]$env:_PS_END] -join [char]10); $sb=[scriptblock]::Create($code); $x=@{Target=$env:_PS_TARGET;Ports=$env:_PS_PORTS;TimeoutMs=[int]$env:_PS_TIMEOUT;Threads=[int]$env:_PS_THREADS;OutCsv=$env:_PS_OUTCSV}; if($env:_PS_RESOLVE -eq '1'){$x.Resolve=$true}; if($env:_PS_QUIET -eq '1'){$x.Quiet=$true}; & $sb @x }"

set "RC=!ERRORLEVEL!"
echo.
if not "%~1"=="--ps" pause
exit /b !RC!

:usage
echo.
echo   ============================================
echo     ac's port scanner v1.0 - Usage
echo   ============================================
echo.
echo   portscannerbyr1.bat                    Interactive menu
echo   portscannerbyr1.bat ^<target^>           Scan top 100 ports
echo   portscannerbyr1.bat ^<target^> ^<ports^>   Range/list/custom preset
echo.
echo   Targets:  IP, hostname, or FQDN
echo   Ports:    top100, top20, web, dev, 1-1024, "22,80,443"
echo.
echo   Options:
echo     --top100 --top20 --web --dev   Preset port lists
echo     --threads N                    Parallel workers (default 64)
echo     --timeout MS                   Per-port timeout ms (default 800)
echo     --resolve                      Show DNS resolution
echo     --quiet                        Only show summary + open ports
echo     --out file.csv                 Export results to CSV
echo.
echo   Examples:
echo     portscannerbyr1.bat 192.168.1.1
echo     portscannerbyr1.bat scanme.nmap.org 1-1024 --threads 100
echo     portscannerbyr1.bat 127.0.0.1 "22,80,443,8080" --resolve
echo     portscannerbyr1.bat 10.0.0.5 --web --out scan.csv
echo.
if "%~1"=="" pause
exit /b 0

:PS1
# __PS1__
param(
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$Ports = 'top100',
    [int]$TimeoutMs = 800,
    [int]$Threads = 64,
    [string]$OutCsv = '',
    [switch]$Resolve,
    [switch]$Quiet
)

$ErrorActionPreference = 'SilentlyContinue'

function Write-Banner {
    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host "    ac's port scanner v1.0  (files=off)" -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host ''
}

function Get-CommonPortSets {
    @{
        top20 = @(21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080)
        top100 = @(
            7,9,13,21,22,23,25,26,37,53,79,80,81,88,106,110,111,113,119,135,139,143,179,199,389,427,443,445,465,513,514,515,543,544,548,554,587,631,646,873,990,993,995,1025,1026,1027,1028,1029,1110,1433,1720,1723,1755,1900,2000,2001,2049,2121,2717,3000,3128,3306,3389,3986,4899,5000,5009,5051,5060,5101,5190,5357,5432,5631,5666,5800,5900,6000,6001,6646,7070,8000,8008,8009,8080,8081,8443,8888,9100,9999,10000,32768,49152,49153,49154,49155,49156,49157
        )
        web = @(80,443,8080,8443,8000,8888,3000,5000,9000)
        dev = @(22,23,445,3389,5900,5985,5986,8080,8443,9000,5432,3306,6379,27017)
    }
}

function Get-ServiceName {
    param([int]$Port)
    $map = @{
        20='ftp-data';21='ftp';22='ssh';23='telnet';25='smtp';53='dns';67='dhcp';68='dhcp';69='tftp'
        80='http';110='pop3';111='rpcbind';123='ntp';135='msrpc';137='netbios-ns';138='netbios-dgm'
        139='netbios-ssn';143='imap';161='snmp';162='snmp-trap';179='bgp';389='ldap';443='https'
        445='microsoft-ds';465='smtps';514='syslog';515='lpd';520='rip';587='submission';631='ipp'
        636='ldaps';873='rsync';993='imaps';995='pop3s';1080='socks';1433='mssql';1521='oracle'
        1723='pptp';2049='nfs';2181='zookeeper';3306='mysql';3389='rdp';4444='metasploit';5000='upnp'
        5060='sip';5432='postgresql';5672='amqp';5900='vnc';5985='winrm-http';5986='winrm-https'
        6379='redis';6667='irc';8000='http-alt';8080='http-proxy';8443='https-alt';8888='sun-answerbook'
        9000='cslistener';9090='zeus-admin';9200='elasticsearch';11211='memcached';27017='mongodb'
    }
    if ($map.ContainsKey($Port)) { return $map[$Port] }
    return ''
}

function Expand-PortSpec {
    param([string]$Spec)
    $sets = Get-CommonPortSets
    $spec = $Spec.Trim().ToLower()
    if ($sets.ContainsKey($spec)) { return ,@($sets[$spec] | Sort-Object -Unique) }
    if ($spec -eq 'all' -or $spec -eq '1-65535') { return ,@(1..65535) }
    $ports = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($part in ($spec -split '[,\s;]+' | Where-Object { $_ })) {
        if ($part -match '^(\d+)\s*-\s*(\d+)$') {
            $a = [int]$Matches[1]; $b = [int]$Matches[2]
            if ($a -gt $b) { $t = $a; $a = $b; $b = $t }
            foreach ($p in $a..$b) {
                if ($p -ge 1 -and $p -le 65535) { [void]$ports.Add($p) }
            }
        }
        elseif ($part -match '^\d+$') {
            $p = [int]$part
            if ($p -ge 1 -and $p -le 65535) { [void]$ports.Add($p) }
        }
        else { throw "Invalid port spec: '$part'" }
    }
    if ($ports.Count -eq 0) { throw 'No valid ports in spec.' }
    return ,@($ports | Sort-Object)
}

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$Timeout
    )
    $client = New-Object System.Net.Sockets.TcpClient
    $iar = $null
    try {
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($Timeout)) {
            return 'filtered'
        }
        try {
            $client.EndConnect($iar)
            return 'open'
        }
        catch {
            return 'closed'
        }
    }
    catch {
        return 'closed'
    }
    finally {
        try { $client.Close() } catch {}
        if ($iar) { try { $iar.AsyncWaitHandle.Close() } catch {} }
    }
}

function Start-PortScan {
    param(
        [string]$HostName,
        [int[]]$PortList,
        [int]$Timeout,
        [int]$MaxThreads
    )
    $results = [System.Collections.Concurrent.ConcurrentDictionary[int, string]]::new()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Max(1, $MaxThreads))
    $pool.Open()
    $worker = {
        param($HostName, $Port, $Timeout)
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $null
        try {
            $iar = $client.BeginConnect($HostName, $Port, $null, $null)
            if (-not $iar.AsyncWaitHandle.WaitOne($Timeout)) { return @{ P = $Port; S = 'filtered' } }
            try { $client.EndConnect($iar); return @{ P = $Port; S = 'open' } }
            catch { return @{ P = $Port; S = 'closed' } }
        }
        catch { return @{ P = $Port; S = 'closed' } }
        finally {
            try { $client.Close() } catch {}
            if ($iar) { try { $iar.AsyncWaitHandle.Close() } catch {} }
        }
    }
    $handles = @()
    foreach ($port in $PortList) {
        $ps = [powershell]::Create().AddScript($worker).AddArgument($HostName).AddArgument($port).AddArgument($Timeout)
        $ps.RunspacePool = $pool
        $handles += [pscustomobject]@{ Pipe = $ps; Handle = $ps.BeginInvoke() }
    }
    foreach ($h in $handles) {
        $r = $h.Pipe.EndInvoke($h.Handle)
        if ($r) { [void]$results.TryAdd([int]$r.P, [string]$r.S) }
        $h.Pipe.Dispose()
    }
    $pool.Close()
    $sw.Stop()
    return [pscustomobject]@{
        Results = $results
        Elapsed = $sw.Elapsed
    }
}

Write-Banner

if ($TimeoutMs -lt 100) { $TimeoutMs = 100 }
if ($TimeoutMs -gt 30000) { $TimeoutMs = 30000 }
if ($Threads -lt 1) { $Threads = 1 }
if ($Threads -gt 512) { $Threads = 512 }

try {
    $portList = Expand-PortSpec -Spec $Ports
}
catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

$displayTarget = $Target
if ($Resolve) {
    try {
        $resolved = [System.Net.Dns]::GetHostAddresses($Target) | Select-Object -First 1
        if ($resolved) {
            Write-Host "  Resolved: $Target -> $($resolved.IPAddressToString)" -ForegroundColor DarkGray
        }
    }
    catch {}
}

Write-Host "  Target   : $displayTarget" -ForegroundColor White
Write-Host "  Ports    : $($portList.Count) port(s)" -ForegroundColor White
Write-Host "  Timeout  : ${TimeoutMs}ms per port" -ForegroundColor White
Write-Host "  Threads  : $Threads" -ForegroundColor White
Write-Host ''
Write-Host '  Scanning...' -ForegroundColor Yellow
Write-Host ''

$scan = Start-PortScan -HostName $Target -PortList $portList -Timeout $TimeoutMs -MaxThreads $Threads
$open = @(); $closed = 0; $filtered = 0

foreach ($entry in ($scan.Results.GetEnumerator() | Sort-Object { [int]$_.Key })) {
    $port = [int]$entry.Key
    $state = $entry.Value
    switch ($state) {
        'open' {
            $open += $port
            $svc = Get-ServiceName -Port $port
            $svcTxt = if ($svc) { "  ($svc)" } else { '' }
            if (-not $Quiet) {
                Write-Host ("  {0,-6} OPEN" -f $port) -NoNewline -ForegroundColor Green
                if ($svcTxt) { Write-Host $svcTxt -ForegroundColor DarkGreen }
                else { Write-Host '' }
            }
        }
        'closed' { $closed++ }
        'filtered' { $filtered++ }
        default { $filtered++ }
    }
}

Write-Host ''
Write-Host '  ============================================' -ForegroundColor Cyan
Write-Host '  Scan complete' -ForegroundColor Cyan
Write-Host '  ============================================' -ForegroundColor Cyan
Write-Host ("  Open     : {0}" -f $open.Count) -ForegroundColor Green
Write-Host ("  Closed   : {0}" -f $closed) -ForegroundColor DarkGray
Write-Host ("  Filtered : {0}" -f $filtered) -ForegroundColor Yellow
Write-Host ("  Time     : {0:N2}s" -f $scan.Elapsed.TotalSeconds) -ForegroundColor White

if ($open.Count -gt 0) {
    Write-Host ''
    Write-Host '  Open ports:' -ForegroundColor Green
    foreach ($p in ($open | Sort-Object)) {
        $svc = Get-ServiceName -Port $p
        if ($svc) { Write-Host "    $p/tcp  $svc" -ForegroundColor Green }
        else { Write-Host "    $p/tcp" -ForegroundColor Green }
    }
}

if ($OutCsv) {
    $rows = foreach ($p in ($portList | Sort-Object)) {
        $st = if ($scan.Results.ContainsKey($p)) { $scan.Results[$p] } else { 'unknown' }
        [pscustomobject]@{
            Target = $Target
            Port = $p
            State = $st
            Service = (Get-ServiceName -Port $p)
            Timestamp = (Get-Date -Format 'o')
        }
    }
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host ''
    Write-Host "  CSV saved: $OutCsv" -ForegroundColor DarkGray
}

Write-Host ''
if ($open.Count -eq 0) { exit 1 }
exit 0
# __ENDPS__
