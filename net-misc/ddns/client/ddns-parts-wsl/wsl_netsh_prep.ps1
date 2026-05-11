# C:\scripts\wsl_netsh_prep_nat.ps1 - run when starting WSL instance joetoo to set up nat'd networking
#
# joetoo_ip4_prefix: first part of local private ipv4 addresses in joetoo domain
# joetoo_ULA_prefix: first part of local stable SLAAC addresses in joetoo domain
#
$JOETOO_ULA_PREFIX = "fd62"
$JOETOO_IP4_PREFIX = "192.168.6"
#
# First, ensure WSL Service is running (Task has Admin, so this works silently)(I used to have to do this manually from time to time)
$svc = Get-Service -Name wslservice -ErrorAction SilentlyContinue
if ($null -eq $svc) {
    Write-Error "WSL Service not found."
} elseif ($svc.Status -ne 'Running') {
    Start-Service -Name wslservice
    Write-Host "WSL Service started."
} else {
    Write-Host "WSL Service already running."
}
# fetch the "registers" set by the launcher (mode and distro)(for nat mode, use joetoo distro; for mirror or bridge, use joetoo_mirror)
$DistroName = [Environment]::GetEnvironmentVariable("WSL_TARGET_DISTRO", "Process")
if (!$DistroName) { $DistroName = [Environment]::GetEnvironmentVariable("WSL_TARGET_DISTRO", "User") }

$Mode = [Environment]::GetEnvironmentVariable("WSL_TARGET_MODE", "Process")
if (!$Mode) { $Mode = [Environment]::GetEnvironmentVariable("WSL_TARGET_MODE", "User") }

# Strict Validation: Exit if variables are missing to prevent unintended behavior
if (!$DistroName -or !$Mode) {
    Write-Error "CRITICAL: WSL_TARGET_DISTRO or WSL_TARGET_MODE environment variables are not set. Script aborting to prevent incorrect configuration."
    exit 1
}


# set default values if variables are missing
if (-not $DistroName) { $DistroName = "joetoo" }
if (-not $Mode)       { $Mode = "nat" }

# clean up existing port 2222 rules to prevent "stale" mappings
# (this part of prep is done for ALL modes - nat, mirror, bridge,
#  to ensure no stale nat rules interfere with the current session)
$stale_addrs = netsh interface portproxy show all | Select-String "2222"  | ForEach-Object { (-split $_)[0] }
foreach ($addr in $stale_addrs) {
    netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=$addr
    netsh interface portproxy delete v6tov4 listenport=2222 listenaddress=$addr
}

# mode-specific branches - new netsh portproxy rules for nat; poke appropriate distro to start up
if ($Mode -eq "nat") {
    # scrape the WSL instance's IP
    # note that this will check for ("poke") an existing joetoo instance or start the WSL init for a new one and leave it running after scraping ip addresses
    # (that makes this #1 of two hooks into the WSL instance joetoo in this setup - the second is in the launch-joetoo.ps1 script itself)
    $wslIp = (wsl -d $DistroName -u joe -e ip -4 addr show eth0 | Select-String -Pattern 'inet\s+([\d\.]+)' | ForEach-Object { $_.Matches.Groups[1].Value })
    
#    $hostV4 = (ipconfig | Select-String "IPv4 Address.*$JOETOO_IP4_PREFIX" | ForEach-Object { $_.ToString().Split(':')[-1].Trim() } | Select-Object -First 1)
#    $hostV6 = (ipconfig | Select-String "IPv6 Address.*$JOETOO_ULA_PREFIX" | ForEach-Object { $_.ToString().Split(':')[-1].Trim() } | Select-Object -First 1)

# use powershell's Get-NetIPAddress to read ip addresses as objects (better/more efficient than ipconfig and pipe(s)
$hostV4 = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
     $_.IPAddress -like "$JOETOO_IP4_PREFIX*"
} | Select-Object -ExpandProperty IPAddress
$hostV6 = Get-NetIPAddress -AddressFamily IPv6 | Where-Object {
    $_.IPAddress -like "$JOETOO_ULA_PREFIX*" -and 
    ($_.PrefixOrigin -eq "RouterAdvertisement") -and 
    ($_.SuffixOrigin -ne "Random")
} | Select-Object -ExpandProperty IPAddress -First 1

    if ($wslIp) {
        if ($hostV6) { netsh interface portproxy add v6tov4 listenport=2222 listenaddress=$hostV6 connectport=2222 connectaddress=$wslIp }
        if ($hostV4) { netsh interface portproxy add v4tov4 listenport=2222 listenaddress=$hostV4 connectport=2222 connectaddress=$wslIp }
    }
}
else {
    # Mirror/Bridge: Just poke the distro to trigger the [boot] OpenRC sequence
    wsl.exe -d $DistroName -u root /bin/true
}

# commit the del / add changes
Restart-Service iphlpsvc -Force


#----[ notes on commands for setting up scheduled task ]--------------------------------------------------------------------------------
# look for pre-existing task(s)
#PS C:\WINDOWS\system32>Get-ScheduledTask -TaskName "*WSL*"
# unregister any pre-existing task
#PS C:\WINDOWS\system32> Unregister-ScheduledTask -TaskName <e.g.WSL_Sync_Task-as-found-above> -Confirm:$false
# check to make sure it is gone
#PS C:\WINDOWS\system32> Get-ScheduledTask -TaskName "*WSL*"
# set up variable $action - run C:\scripts\wsl_netsh_prep.ps1 with powershell under an execution policy bypass
#PS C:\WINDOWS\system32> $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File C:\scripts\wsl_netsh_prep.ps1'
# set up variable $principal - authorize user (joebr) to run sched tasks from LogonType S4U and runlevel Highest
# note: S4U tasks run in a non-interactive session; as a result there won't be a PowerShell window pop up when the task runs
# (and thus the Write-Host output will not be displayed when this script runs as a scheduled task)
#PS C:\WINDOWS\system32> $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
# now force-register the $action and $principle as scheduled task named WSL_Net_Prep
#PS C:\WINDOWS\system32> Register-ScheduledTask -TaskName "WSL_Net_Prep" -Action $action -Principal $principal -Force
# it should respond like this:
#TaskPath                                       TaskName                          State
#--------                                       --------                          -----
#\                                              WSL_Net_Prep                      Ready
#PS C:\WINDOWS\system32>

