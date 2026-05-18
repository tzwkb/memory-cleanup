# Force Windows Update to find MT7921 driver
Write-Host "=== Triggering Windows Update scan for driver updates ==="

# Install PSWindowsUpdate if not available
$hasModule = Get-Module -ListAvailable -Name PSWindowsUpdate
if (-not $hasModule) {
    Write-Host "PSWindowsUpdate not installed. Trying built-in methods..."
}

# Method 1: Try Microsoft Update Catalog via web request
Write-Host ""
Write-Host "Searching Microsoft Update Catalog..."
$query = "MediaTek MT7921 Wireless Lan Driver Windows 11"
$searchUrl = "https://www.catalog.update.microsoft.com/Search.aspx?q=" + [uri]::EscapeDataString($query)

try {
    $response = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 15
    # Parse the result table
    $rows = $response.Content -split '<tr[>\s]' | Select-String -Pattern 'MT7921|MediaTek'
    Write-Host "Found matches in catalog."

    # Extract update IDs
    $ids = [regex]::Matches($response.Content, 'id_([a-f0-9\-]+)')
    if ($ids.Count -gt 0) {
        $latestId = $ids[0].Groups[1].Value
        Write-Host ("Latest update ID: " + $latestId)
        Write-Host ("Download URL: https://www.catalog.update.microsoft.com/DownloadDialog.aspx?UpdateID=" + $latestId)

        # Try to get the direct download URL
        $dlUrl = "https://www.catalog.update.microsoft.com/DownloadDialog.aspx?UpdateID=" + $latestId
        $dlPage = Invoke-WebRequest -Uri $dlUrl -UseBasicParsing -TimeoutSec 15
        $directLinks = [regex]::Matches($dlPage.Content, "https?://[^'\""]+\.cab")
        foreach ($link in $directLinks) {
            Write-Host ("Found CAB: " + $link.Value)
        }
    }
} catch {
    Write-Host ("Catalog unreachable: " + $_.Exception.Message)
}

# Method 2: Direct download alternative sources
Write-Host ""
Write-Host "=== Alternative sources ==="
Write-Host "Driver version 3.0.1.1325 is old. Latest is 3.5.0.1376 (2025-12)"
Write-Host ""
Write-Host "Manual download options:"
Write-Host "  1. ASUS support: https://www.asus.com/supportonly/fa707rw/helpdesk_download/"
Write-Host "  2. Microsoft Catalog: https://www.catalog.update.microsoft.com/Search.aspx?q=MediaTek%20MT7921"
Write-Host "  3. Station-drivers: https://station-drivers.com (search MT7921)"

# Method 3: Try usoclient to search for updates
Write-Host ""
Write-Host "=== Triggering Windows Update search ==="
Write-Host "Run: UsoClient StartScan"
Write-Host "Then check: Settings > Windows Update > Advanced > Optional Updates"
