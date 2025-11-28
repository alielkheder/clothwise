# Check existing ngrok firewall rules
Write-Host "Checking existing ngrok firewall rules..." -ForegroundColor Yellow
$existingRules = Get-NetFirewallRule | Where-Object {$_.DisplayName -like '*ngrok*'}

if ($existingRules) {
    Write-Host "Found existing ngrok rules:" -ForegroundColor Green
    $existingRules | Select-Object DisplayName,Enabled,Direction,Action | Format-Table
} else {
    Write-Host "No existing ngrok firewall rules found." -ForegroundColor Red
}

# Add firewall rules for ngrok
Write-Host "`nAdding firewall rules for ngrok..." -ForegroundColor Yellow

try {
    # Inbound rule
    New-NetFirewallRule -DisplayName "ngrok Inbound" `
        -Direction Inbound `
        -Program "C:\Users\yassi\Downloads\ngrok.exe" `
        -Action Allow `
        -Profile Any `
        -Enabled True `
        -ErrorAction Stop
    Write-Host "Added ngrok Inbound rule successfully!" -ForegroundColor Green
} catch {
    Write-Host "Inbound rule might already exist or error: $_" -ForegroundColor Yellow
}

try {
    # Outbound rule
    New-NetFirewallRule -DisplayName "ngrok Outbound" `
        -Direction Outbound `
        -Program "C:\Users\yassi\Downloads\ngrok.exe" `
        -Action Allow `
        -Profile Any `
        -Enabled True `
        -ErrorAction Stop
    Write-Host "Added ngrok Outbound rule successfully!" -ForegroundColor Green
} catch {
    Write-Host "Outbound rule might already exist or error: $_" -ForegroundColor Yellow
}

Write-Host "`nFirewall configuration complete!" -ForegroundColor Green
