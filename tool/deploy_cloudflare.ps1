# Script to build and deploy SpreadLog to Cloudflare
$ErrorActionPreference = "Stop"

# PowerShell does not consistently turn native command failures into exceptions.
function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE. Deployment stopped."
    }
}

# The Cloudflare login spans several accounts and the account ID is kept out
# of the repo. Wrangler reads it from the environment or the git-ignored .env;
# load .env here too so the check below sees the same value.
if (Test-Path .env) {
    foreach ($line in Get-Content .env) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            if (-not [Environment]::GetEnvironmentVariable($Matches[1])) {
                [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2])
            }
        }
    }
}
if (-not $env:CLOUDFLARE_ACCOUNT_ID) {
    throw "Set CLOUDFLARE_ACCOUNT_ID in .env (or the environment) to the account hosting the spreadlog Worker."
}

$buildCommit = git rev-parse --short HEAD
Assert-NativeSuccess "Resolve build commit"

Write-Host "==> Syncing Web Assets (sqlite3.wasm & drift_worker.js)..." -ForegroundColor Cyan
dart run tool/update_web_assets.dart
Assert-NativeSuccess "Sync web assets"

Write-Host "==> Building Flutter Web release..." -ForegroundColor Cyan
flutter build web --release "--dart-define=BUILD_COMMIT=$buildCommit"
Assert-NativeSuccess "Build Flutter web"

Write-Host "==> Validating Cloudflare deployment package..." -ForegroundColor Cyan
npx --no-install wrangler deploy --dry-run
Assert-NativeSuccess "Validate deployment"

Write-Host "==> Deploying to Cloudflare..." -ForegroundColor Cyan
npx --no-install wrangler deploy
Assert-NativeSuccess "Deploy Cloudflare"
