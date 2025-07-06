# PowerShell script to help with Windows Display Scaling for Flutter apps
# Run this script as Administrator

Write-Host "=== Flutter Windows Display Scaling Fix ===" -ForegroundColor Green
Write-Host ""

# Check current scaling
$currentScaling = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -ErrorAction SilentlyContinue
if ($currentScaling) {
    $scalingPercent = ($currentScaling.LogPixels / 96) * 100
    Write-Host "Current scaling: $scalingPercent%" -ForegroundColor Yellow
} else {
    Write-Host "Current scaling: 100% (default)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Manual Steps to Fix Text Blurriness ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Right-click on Desktop -> Display settings"
Write-Host "2. Set 'Scale and layout' to 100% (Recommended for Flutter apps)"
Write-Host "3. Sign out and sign back in for changes to take effect"
Write-Host ""
Write-Host "Alternative method:"
Write-Host "1. Right-click on prompt_manager.exe -> Properties"
Write-Host "2. Go to 'Compatibility' tab"
Write-Host "3. Check 'Override high DPI scaling behavior'"
Write-Host "4. Select 'System' from dropdown"
Write-Host "5. Click OK"
Write-Host ""
Write-Host "=== Additional Registry Fix (Run as Admin) ===" -ForegroundColor Red
$response = Read-Host "Do you want to apply registry fix for DPI awareness? (y/n)"

if ($response -eq 'y' -or $response -eq 'Y') {
    try {
        # Set DPI awareness in registry
        $regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
        $exePath = (Get-Location).Path + "\build\windows\x64\runner\Debug\prompt_manager.exe"
        
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force
        }
        
        Set-ItemProperty -Path $regPath -Name $exePath -Value "~ DPIUNAWARE"
        Write-Host "Registry fix applied successfully!" -ForegroundColor Green
        Write-Host "Restart the Flutter app to see changes." -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error applying registry fix: $_" -ForegroundColor Red
        Write-Host "Please run as Administrator" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Font Size Increase Applied ===" -ForegroundColor Green
Write-Host "- Display Large: 24px -> 28px"
Write-Host "- Headline Small: 18px -> 20px" 
Write-Host "- Body Large: 16px -> 18px"
Write-Host "- Body Medium: 15px -> 16px"
Write-Host "- Body Small: 13px -> 14px"
Write-Host "- Changed from Google Fonts to Segoe UI (Windows native font)"
Write-Host ""
Write-Host "Run 'flutter run' to test the changes!" -ForegroundColor Green 