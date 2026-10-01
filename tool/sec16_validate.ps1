param(
    [string]$ReleaseApiBase = "https://example.invalid/api/security"
)

$ErrorActionPreference = "Stop"

function Invoke-FlutterStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host "`n==> $Name" -ForegroundColor Cyan
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Invoke-FlutterStep -Name "flutter pub get" -Arguments @("pub", "get")
Invoke-FlutterStep -Name "flutter gen-l10n" -Arguments @("gen-l10n")

Invoke-FlutterStep -Name "APH.42 + SEC.16 targeted regression + runtime remediation" -Arguments @(
    "test",
    "test/security_api_localization_test.dart",
    "test/api_security_dashboard_repository_test.dart",
    "test/api_visitor_repository_test.dart",
    "test/api_security_package_repository_test.dart",
    "test/api_patrol_repository_test.dart",
    "test/mock_patrol_repository_test.dart",
    "test/patrol_photo_evidence_widget_test.dart",
    "test/sec16_production_readiness_test.dart",
    "test/sec16_runtime_remediation_test.dart"
)

Invoke-FlutterStep -Name "flutter analyze" -Arguments @("analyze")
Invoke-FlutterStep -Name "full flutter test" -Arguments @("test")
Invoke-FlutterStep -Name "debug APK" -Arguments @("build", "apk", "--debug")
Invoke-FlutterStep -Name "release APK compile" -Arguments @(
    "build",
    "apk",
    "--release",
    "--dart-define=SECURITY_API_BASE_URL=$ReleaseApiBase"
)

Write-Host "`nSEC.16 automated validation completed successfully." -ForegroundColor Green
Write-Host "Release URL used for this run: $ReleaseApiBase"
Write-Host "If this is example.invalid, it is compile-only evidence. Run real-device/backend smoke separately."
