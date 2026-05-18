# Open AMD driver download page in browser, then auto-install
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== AMD Driver-Only Install ==="
Write-Host ""

# Step 1: Open download page in browser
Write-Host "Opening AMD driver page in browser..."
Write-Host ""

$downloadPage = "https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen/ryzen-6000-series/amd-ryzen-7-6800h.html"
Start-Process $downloadPage

Write-Host ">>> DO THIS NOW: <<<"
Write-Host "  1. Click 'Download' for Adrenalin 26.2.2 (WHQL)"
Write-Host "  2. Save to: Downloads\amd-driver-26.2.2.exe"
Write-Host "  3. Come back here and type: go"
Write-Host ""
Write-Host "I'll then auto-extract and install driver-only (no Adrenalin bloat)."
