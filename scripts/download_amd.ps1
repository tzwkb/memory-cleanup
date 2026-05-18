# Download AMD driver via PowerShell (better at handling CDN auth)
$url = "https://drivers.amd.com/drivers/amd-software-adrenalin-edition-26.2.2-win10-win11-feb26-rdna.exe"
$output = "$env:USERPROFILE\Downloads\amd-driver-26.2.2.exe"

Write-Host "Downloading AMD 26.2.2 driver..."
Write-Host "URL: $url"
Write-Host "Save: $output"

try {
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -Headers @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Accept" = "*/*"
        "Referer" = "https://www.amd.com/"
    }
    $size = (Get-Item $output).Length
    if ($size -gt 1000000) {
        Write-Host ("OK  Downloaded: " + [math]::Round($size/1MB) + " MB")
    } else {
        Write-Host ("FAIL: File too small (" + $size + " bytes)")
    }
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message)
    Write-Host "Trying alternative download URL..."

    # Try alternate: AMD auto-detect tool
    $altUrl = "https://www.amd.com/en/support/download/drivers.html"
    Write-Host "Cannot auto-download. Please download manually:"
    Write-Host "  1. Open: https://www.amd.com/en/support/download/drivers.html"
    Write-Host "  2. Select: Processors with Radeon Graphics -> Ryzen 7 6800H"
    Write-Host "  3. Download: Adrenalin 26.2.2 (WHQL)"
    Write-Host "  4. Save to: $output"
    Write-Host "  5. Run: install_amd_driver_only.ps1"
}
