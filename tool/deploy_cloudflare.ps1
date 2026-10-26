# Script to build and deploy SpreadLog to Cloudflare
$ErrorActionPreference = "Stop"

# PowerShell does not consistently turn native command failures into exceptions.
function Assert-NativeSuccess([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE. Deployment stopped."
    }
}

# The Cloudflare login spans several accounts and the account ID is kept out
# of the repo, so wrangler reads it from this environment variable.
if (-not $env:CLOUDFLARE_ACCOUNT_ID) {
    throw "Set CLOUDFLARE_ACCOUNT_ID to the account hosting the spreadlog Worker, e.g. setx CLOUDFLARE_ACCOUNT_ID <id> (then open a new terminal)."
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
