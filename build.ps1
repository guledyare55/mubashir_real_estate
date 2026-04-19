# Mubashir Real Estate Build Helper
Write-Host "Checking for Node.js environment..." -ForegroundColor Cyan

if (Get-Command "npx" -ErrorAction SilentlyContinue) {
    Write-Host "Starting Interactive Build Engine..." -ForegroundColor Green
    # Using ts-node via npx to run the TS script without permanent installs
    npx tsx scripts/build.ts
} else {
    Write-Host "Error: Node.js/npm is required to run the build automation suite." -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/"
}
