while ($true) {
    $changes = git status --porcelain
    if ($changes) {
        git add .
        git commit -m "Auto-save $(Get-Date -Format 'HH:mm')"
        Write-Host "Auto-saved at $(Get-Date -Format 'HH:mm:ss')"
    }
    Start-Sleep 300
}
