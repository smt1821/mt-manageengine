# Define URL for Chrome Enterprise 64-bit MSI
$chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"

# Define download location
$downloadPath = "$env:TEMP\GoogleChromeEnterprise64.msi"

Write-Host "Downloading Google Chrome Enterprise MSI..."

try {
    Invoke-WebRequest -Uri $chromeUrl -OutFile $downloadPath -UseBasicParsing
    Write-Host "Download completed: $downloadPath"
}
catch {
    Write-Host "Download failed:" $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "Installing Google Chrome silently..."

# Install silently
$installArgs = "/i `"$downloadPath`" /qn /norestart"

$process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru

if ($process.ExitCode -eq 0) {
    Write-Host "Google Chrome installed successfully!" -ForegroundColor Green
} else {
    Write-Host "Chrome installation failed. Exit code: $($process.ExitCode)" -ForegroundColor Red
}

# Optional: Cleanup installer file
Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
