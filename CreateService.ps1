#---- Path to NSSM ----#
$nssm = 'D:\Tools\nssm.exe'

#---- Path to script to run as a service ----#
$ScriptPath = 'D:\Resources\UnisphereExporter\StartListener.ps1'

#---- Name of new service ----#
$ServiceName = 'UnisphereExporter'

#---- Path to PowerShell.exe ----#
$ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

#---- Arguements to pass to Posh ----#
$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptPath

#---- Create the service ----#
& $nssm install $ServiceName $ServicePath $ServiceArguments

#---- Check the service ----#
& $nssm status $ServiceName

#---- Start the service ----#
& $nssm start $ServiceName

#---- Validate the service ----#
& $nssm status $ServiceName