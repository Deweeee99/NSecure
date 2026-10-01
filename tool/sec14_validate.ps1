param(
    [string]$ApiBaseUrl = "https://example.invalid/api/security"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if ($ApiBaseUrl -notmatch '^https://.+/api/security/?$') {
    throw "ApiBaseUrl must be HTTPS and end with /api/security"
}

Push-Location $projectRoot
try {
    Write-Host "[SEC.14] flutter pub get"
    flutter pub get

    Write-Host "[SEC.14] flutter gen-l10n"
    flutter gen-l10n

    Write-Host "[SEC.14] flutter analyze"
    flutter analyze

    Write-Host "[SEC.14] flutter test"
    flutter test

    Write-Host "[SEC.14] flutter build apk --debug"
    flutter build apk --debug

    Write-Host "[SEC.14] flutter build apk --release"
    flutter build apk --release "--dart-define=SECURITY_API_BASE_URL=$ApiBaseUrl"

    Write-Host "[SEC.14] Automated gate complete. Real-device/backend smoke is still required for final closure."
}
finally {
    Pop-Location
}
