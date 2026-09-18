Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Running Project Quality & Health Checks " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Verify/Download web assets
Write-Host "`n[1/4] Checking Web Runtime Assets..." -ForegroundColor Yellow
dart run tool/update_web_assets.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "Asset check failed!" -ForegroundColor Red
    exit 1
}

# 2. Build runner (ensure all generated code is up-to-date)
Write-Host "`n[2/4] Running Code Generation..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build runner failed!" -ForegroundColor Red
    exit 1
}

# 3. Static Analysis
Write-Host "`n[3/4] Running Flutter Analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Static analysis found issues!" -ForegroundColor Red
    exit 1
}

# 4. Unit & Widget Tests
Write-Host "`n[4/4] Executing Test Suite..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  All Checks Passed Cleanly!             " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

