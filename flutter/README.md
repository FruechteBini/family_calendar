# Familienkalender — Flutter Cross-Platform App

Unified codebase for Web, Android, and iOS replacing three separate implementations.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.24+ (Dart 3.3+) |
| State | Riverpod 2 |
| HTTP | Dio |
| Routing | GoRouter |
| Local DB | Drift (SQLite) |
| Auth | JWT via flutter_secure_storage |
| Speech | speech_to_text |
| Sync | workmanager |

## Getting Started

```bash
cd flutter
flutter pub get
flutter run                    # Debug (connected device)
flutter run -d chrome          # Web
flutter build web --wasm       # Production web build
flutter build apk              # Android APK
flutter build ios              # iOS (requires macOS + Xcode)
```

## Architecture

```
lib/
├── main.dart                  # Entry point
├── app/                       # App shell, router, theme
├── core/                      # API client, auth, database, sync, theme
├── features/                  # Feature modules (calendar, todos, meals, ...)
│   └── <feature>/
│       ├── data/              # Repository + DTOs
│       ├── domain/            # Models
│       └── presentation/      # Screens + widgets
└── shared/                    # Reusable widgets + utilities
```

## Features

All features from the original Web, Android, and iOS apps:
- Calendar (month/week/3-day/day views)
- Todos with proposals, sub-tasks, filters
- Recipes with Cookidoo and URL import
- Weekly meal planning with AI suggestions
- Shopping list with AI sorting
- Pantry tracking with alerts
- Voice commands (13 action types)
- Knuspr integration
- Offline support with background sync
- Dark mode
- Family management (create/join with invite code)

## Docker (Web)

```bash
docker build -t familienkalender-web .
docker run -p 80:80 familienkalender-web
```

## CI/CD

GitHub Actions workflow in `.github/workflows/build.yml` builds all three platforms on push to main.
