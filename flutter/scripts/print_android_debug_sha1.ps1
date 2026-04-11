# SHA-1 des Android-Debug-Keystores (für Google Cloud → Android OAuth-Client).
# Ausführen:  powershell -File flutter/scripts/print_android_debug_sha1.ps1

$keystore = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (-not (Test-Path $keystore)) {
    Write-Error "Keystore nicht gefunden: $keystore (einmal flutter/android bauen oder Emulator starten)."
    exit 1
}

& keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android
