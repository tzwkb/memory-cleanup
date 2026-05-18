# Check GPU models and drivers
Write-Host "=== GPU Information ==="
Get-CimInstance Win32_VideoController | ForEach-Object {
    Write-Host ("")
    Write-Host ("Name: " + $_.Name)
    Write-Host ("Driver Version: " + $_.DriverVersion)
    Write-Host ("Adapter RAM: " + [math]::Round($_.AdapterRam/1GB) + " GB")
    Write-Host ("Status: " + $_.Status)
}

# Check CPU for iGPU model
Write-Host ""
Write-Host "=== CPU ==="
Get-CimInstance Win32_Processor | ForEach-Object {
    Write-Host ("Name: " + $_.Name)
}

# Check current AMD driver install path
Write-Host ""
Write-Host "=== AMD Install Path ==="
$amdDirs = @(
    "C:\Program Files\AMD",
    "C:\Program Files (x86)\AMD"
)
foreach ($dir in $amdDirs) {
    if (Test-Path $dir) {
        Write-Host ("Found: " + $dir)
        Get-ChildItem $dir -Directory | ForEach-Object { Write-Host ("  " + $_.Name) }
    }
}
