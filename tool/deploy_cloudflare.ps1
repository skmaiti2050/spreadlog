# Script to build and deploy SpreadLog to Cloudflare
$ErrorActionPreference = "Stop"

Write-Host "==> Syncing Web Assets (sqlite3.wasm & drift_worker.js)..." -ForegroundColor Cyan
dart run tool/update_web_assets.dart

Write-Host "==> Building Flutter Web release..." -ForegroundColor Cyan
flutter build web --release

Write-Host "==> Deploying to Cloudflare..." -ForegroundColor Cyan
npx wrangler deploy
