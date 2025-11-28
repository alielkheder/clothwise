$response = Invoke-RestMethod 'http://localhost:4040/api/tunnels'
if ($response.tunnels -and $response.tunnels.Count -gt 0) {
    $response.tunnels[0].public_url
} else {
    Write-Host "No tunnels found"
}
