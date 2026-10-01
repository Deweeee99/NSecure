param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

Write-Host "SEC.8 Android preparation" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"

Push-Location $ProjectRoot
try {
    Write-Host "Adding pinned Flutter dependencies..." -ForegroundColor Cyan
    flutter pub add 'flutter_secure_storage:^10.3.1'
    flutter pub add 'mobile_scanner:^7.4.0'

    $gradlePath = Join-Path $ProjectRoot 'android\app\build.gradle.kts'
    if (-not (Test-Path $gradlePath)) {
        throw "Android app build.gradle.kts not found at $gradlePath"
    }

    Write-Host "Restoring Flutter-managed compileSdk baseline..." -ForegroundColor Cyan
    $gradleContent = Get-Content -Raw -Path $gradlePath
    $compileSdkRegex = [regex]'(?m)^(\s*)compileSdk\s*=\s*[^\r\n]+'
    if (-not $compileSdkRegex.IsMatch($gradleContent)) {
        throw 'Could not find compileSdk assignment in android/app/build.gradle.kts.'
    }
    $gradleContent = $compileSdkRegex.Replace(
        $gradleContent,
        '${1}compileSdk = flutter.compileSdkVersion',
        1
    )
    [System.IO.File]::WriteAllText(
        $gradlePath,
        $gradleContent,
        (New-Object System.Text.UTF8Encoding($false))
    )

    $manifestPath = Join-Path $ProjectRoot 'android\app\src\main\AndroidManifest.xml'
    if (-not (Test-Path $manifestPath)) {
        throw "AndroidManifest.xml not found at $manifestPath"
    }

    Write-Host "Hardening Android manifest..." -ForegroundColor Cyan
    [xml]$manifest = Get-Content -Raw -Path $manifestPath
    $manifestElement = $manifest.DocumentElement
    $application = $manifest.manifest.application
    if ($null -eq $manifestElement -or $null -eq $application) {
        throw 'AndroidManifest.xml must contain <manifest> and <application> elements.'
    }

    $androidNs = 'http://schemas.android.com/apk/res/android'
    $application.SetAttribute('allowBackup', $androidNs, 'false')

    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
    $namespaceManager.AddNamespace('android', $androidNs)

    function Ensure-UsesPermission([string]$permissionName) {
        $escapedName = $permissionName.Replace("'", "&apos;")
        $existing = $manifestElement.SelectSingleNode(
            "uses-permission[@android:name='$escapedName']",
            $namespaceManager
        )
        if ($null -eq $existing) {
            $node = $manifest.CreateElement('uses-permission')
            $node.SetAttribute('name', $androidNs, $permissionName)
            [void]$manifestElement.InsertBefore($node, $application)
        }
    }

    Ensure-UsesPermission 'android.permission.INTERNET'
    Ensure-UsesPermission 'android.permission.CAMERA'

    $cameraFeature = $manifestElement.SelectSingleNode(
        "uses-feature[@android:name='android.hardware.camera.any']",
        $namespaceManager
    )
    if ($null -eq $cameraFeature) {
        $cameraFeature = $manifest.CreateElement('uses-feature')
        $cameraFeature.SetAttribute('name', $androidNs, 'android.hardware.camera.any')
        $cameraFeature.SetAttribute('required', $androidNs, 'false')
        [void]$manifestElement.InsertBefore($cameraFeature, $application)
    }
    else {
        $cameraFeature.SetAttribute('required', $androidNs, 'false')
    }

    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.IndentChars = '    '
    $settings.NewLineChars = "`r`n"
    $settings.NewLineHandling = 'Replace'
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)

    $writer = [System.Xml.XmlWriter]::Create($manifestPath, $settings)
    try {
        $manifest.Save($writer)
    }
    finally {
        $writer.Dispose()
    }

    Write-Host "compileSdk restored to Flutter-managed baseline." -ForegroundColor Green

    $gradleWrapper = Join-Path $ProjectRoot 'android\gradlew.bat'
    if (Test-Path $gradleWrapper) {
        Write-Host "Stopping Gradle daemon so the newly installed SDK target is reloaded..." -ForegroundColor Cyan
        Push-Location (Join-Path $ProjectRoot 'android')
        try {
            & .\gradlew.bat --stop | Out-Host
        }
        finally {
            Pop-Location
        }
    }

    Write-Host "SEC.8 Android preparation complete." -ForegroundColor Green
    Write-Host "Dependencies: flutter_secure_storage ^10.3.1, mobile_scanner ^7.4.0"
    Write-Host "Android compileSdk: flutter.compileSdkVersion"
    Write-Host "Android backup: disabled"
    Write-Host "Android permissions: INTERNET + CAMERA"
    Write-Host "Camera hardware: optional (manual verification remains supported)"
}
finally {
    Pop-Location
}
