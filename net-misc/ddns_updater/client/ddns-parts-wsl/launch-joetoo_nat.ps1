# C:\scripts\launch-joetoo_<mode>.ps1 - this is what will run when right-click terminal and select "joetoo"
# (copies .wslconfig with nat setup into play, and calls for scheduled task to elevate priv and set up networking)
#
param(
    [string]$Mode = "nat" 
)
[string]$DistroName = "joetoo-$Mode"
# Set the intended state in the User environment block
[Environment]::SetEnvironmentVariable("WSL_TARGET_DISTRO", "$DistroName", "User")
[Environment]::SetEnvironmentVariable("WSL_TARGET_MODE", "$Mode", "User")
#
# force shutdown to ensure the new config is read
wsl --shutdown
#
# swap the config
Copy-Item "$HOME\.wslconfig.$Mode" "$HOME\.wslconfig" -Force
#
# 3. trigger the elevated task (silent, no UAC) to set up portproxy rules for WSL joetoo so it's nat'd network will work
# (this task runs C:\scripts\wsl_netsh_prep.ps1, which reads distro and mode from the environment block)
Get-ScheduledTask -TaskName "WSL_Net_Prep" | Start-ScheduledTask
#
# wait a moment for the background task to initialize the VM
Start-Sleep -Seconds 2
#
# launch the terminal (WSL will use the [user] block from wsl.conf so it doesn't start as root)
#   note that because the "schtasks.exe -ArgumentList includes C:\scripts\wsl_netsh_prep.ps1
#   (which runs wsl.exe -d joetoo... to "poke" the instance, etc), that instance of joetoo is already
# started an running, so the command below will "attach" to it as the second of two "hooks" into it in this setup
wsl.exe -d $DistroName
