# todo_app_mobile_frontend

A minimalist, modern Flutter todo app with a dark theme and offline persistence.

## Features

- Add, edit, complete, delete tasks
- View active or completed tasks
- Persistent local storage powered by SQLite (sqflite)
- Minimal, modern dark UI (primary: #1976d2, secondary: #424242, accent: #ffca28)
- Cards UI and floating action button
- Extensible via `.env` for future configuration

## Getting Started

Run:
```bash
flutter pub get
flutter run
```

## Environment Variables

Environment configuration is loaded from `.env` via [flutter_dotenv](https://pub.dev/packages/flutter_dotenv).
You may add future config entries in `.env`.

## License

MIT
