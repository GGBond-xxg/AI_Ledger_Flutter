# Run from Flutter project root after `flutter create --org com.ggbong --project-name ledger .`
# This script localizes the Android app label and helps enforce package id.

$ErrorActionPreference = "Stop"

$manifest = "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifest) {
  $content = Get-Content $manifest -Raw
  $content = $content -replace 'android:label="[^"]*"', 'android:label="@string/app_name"'
  if ($content -notmatch 'android.permission.INTERNET') {
    $content = [regex]::Replace($content, '<manifest([^>]*)>', {
      param($m)
      "<manifest$($m.Groups[1].Value)>`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
    }, 1)
  }
  Set-Content -Path $manifest -Value $content -Encoding UTF8
}

New-Item -ItemType Directory -Force -Path "android/app/src/main/res/values" | Out-Null
New-Item -ItemType Directory -Force -Path "android/app/src/main/res/values-zh" | Out-Null

Set-Content -Path "android/app/src/main/res/values/strings.xml" -Value @'
<resources>
    <string name="app_name">Ledger</string>
</resources>
'@ -Encoding UTF8

Set-Content -Path "android/app/src/main/res/values-zh/strings.xml" -Value @'
<resources>
    <string name="app_name">记账</string>
</resources>
'@ -Encoding UTF8

Write-Host "Android label resources have been configured."
Write-Host "Please verify applicationId/namespace is com.ggbong.ledger in android/app/build.gradle or build.gradle.kts."
