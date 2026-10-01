param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

Write-Host "SEC.9A Localization preparation" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"

Push-Location $ProjectRoot
try {
    Write-Host "Adding Flutter localization dependencies..." -ForegroundColor Cyan
    flutter pub add flutter_localizations --sdk=flutter
    flutter pub add intl
    flutter pub add 'shared_preferences:^2.5.3'

    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    if (-not (Test-Path $pubspecPath)) {
        throw "pubspec.yaml not found at $pubspecPath"
    }

    Write-Host "Enabling Flutter generated localizations..." -ForegroundColor Cyan
    $pubspec = [System.IO.File]::ReadAllText($pubspecPath)

    if ($pubspec -match '(?m)^\s{2}generate:\s*.*$') {
        $pubspec = [regex]::Replace(
            $pubspec,
            '(?m)^\s{2}generate:\s*.*$',
            '  generate: true',
            1
        )
    }
    elseif ($pubspec -match '(?m)^flutter:\s*$') {
        $pubspec = [regex]::Replace(
            $pubspec,
            '(?m)^flutter:\s*$',
            "flutter:`r`n  generate: true",
            1
        )
    }
    else {
        throw 'Could not find the flutter: section in pubspec.yaml.'
    }

    [System.IO.File]::WriteAllText(
        $pubspecPath,
        $pubspec,
        (New-Object System.Text.UTF8Encoding($false))
    )

    Write-Host "Resolving dependencies..." -ForegroundColor Cyan
    flutter pub get

    Write-Host "Generating AppLocalizations from ARB files..." -ForegroundColor Cyan
    flutter gen-l10n

    $generated = Join-Path $ProjectRoot 'lib\l10n\app_localizations.dart'
    if (-not (Test-Path $generated)) {
        throw "Generated localization file not found at $generated"
    }

    Write-Host "SEC.9A localization preparation complete." -ForegroundColor Green
    Write-Host "Locales: id, en"
    Write-Host "Generated localization: lib\l10n\app_localizations.dart"
    Write-Host "Locale preference: shared_preferences (security.locale.language_code)"
    Write-Host "Backend API wire values: unchanged"
}
finally {
    Pop-Location
}
