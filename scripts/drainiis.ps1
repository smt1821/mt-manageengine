Write-Output "Stopping IIS app pool test2 for maintenance..."
Import-Module WebAdministration

Stop-WebAppPool -Name "test2"

Write-Output "test2 app pool stopped. Azure LB will mark this VM Unhealthy."
exit 0
