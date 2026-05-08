# C:\scripts\launch-joetoo.ps1 - this is what will run when right-click terminal and select "joetoo"
#
# trigger the elevated task (silent, no UAC) to set up portproxy rules for WSL joetoo so it's nat'd network will work
#
Start-Process "schtasks.exe" -ArgumentList "/run /tn `"WSL_Sync_Task`"" -WindowStyle Hidden -Wait

# launch the terminal (WSL will use the [user] block from wsl.conf)
#   note that because the "schtasks.exe -ArgumentList includes C:\scripts\wsl_netsh_sync.ps1 (which runs wsl -d joetoo... to get ip addresses etc)
#   that instance of joetoo is already started an running, so the command below will "attach" to it as the second of two "hooks" into it in this setup
wsl.exe -d joetoo