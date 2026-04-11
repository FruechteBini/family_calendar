## Push Benachrichtigungen (FCM) Setup

### Backend (FastAPI)

- **Option A (empfohlen)**: Service-Account JSON direkt als Env-Var
  - Setze `FIREBASE_CREDENTIALS_JSON` in `backend/.env`
- **Option B**: Pfad zur Service-Account Datei
  - Setze `FIREBASE_CREDENTIALS_PATH` in `backend/.env`

Beispiel-Env-File: `backend/.env.example`

Wenn **keine** Firebase-Credentials gesetzt sind, ist Push **deaktiviert** (kein Crash).

### Flutter (Android/iOS/Web)

Dieses Repo erwartet Firebase-Konfigurationsdateien aus deinem Firebase-Projekt:

- **Android**: `flutter/android/app/google-services.json`
- **iOS**: `flutter/ios/Runner/GoogleService-Info.plist`

Für Web-Push wird zusätzlich Firebase Web-Konfiguration + Service Worker benötigt.
Wenn Firebase nicht korrekt konfiguriert ist, bleibt Push in der App automatisch deaktiviert.

