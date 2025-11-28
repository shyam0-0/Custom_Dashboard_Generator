Write-Host "Checking Windows Exporter installation..." -ForegroundColor Cyan

# Path to the Windows Exporter MSI installer (included in your project)
$exporterMsi = "$PSScriptRoot\windows_exporter-0.31.3-amd64.msi"

# Service name
$serviceName = "windows_exporter"

# Check if service exists
$svc = Get-Service -ErrorAction SilentlyContinue -Name $serviceName

if ($svc) {
    Write-Host "Windows Exporter is already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing Windows Exporter..." -ForegroundColor Yellow
    
    if (!(Test-Path $exporterMsi)) {
        Write-Host "ERROR: Installer not found at $exporterMsi" -ForegroundColor Red
        exit 1
    }

    # Install MSI silently
    Start-Process msiexec.exe -ArgumentList "/i `"$exporterMsi`" /qn" -Wait

    # Verify installation
    $svcAfter = Get-Service -ErrorAction SilentlyContinue -Name $serviceName
    if (!$svcAfter) {
        Write-Host "ERROR: Installation failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "Windows Exporter installed successfully." -ForegroundColor Green
}

# Start service
Write-Host "Starting Windows Exporter service..." -ForegroundColor Cyan
Start-Service -Name $serviceName -ErrorAction SilentlyContinue
Set-Service -Name $serviceName -StartupType Automatic

Write-Host "Windows Exporter is running." -ForegroundColor Green
