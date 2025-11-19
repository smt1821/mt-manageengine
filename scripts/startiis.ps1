Write-Output "Starting IIS app pool test2 after maintenance..."
Import-Module WebAdministration

Start-WebAppPool -Name "test2"

Write-Output "test2 app pool started. Azure LB will mark this VM Healthy."
exit 0
