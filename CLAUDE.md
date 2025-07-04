# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a simple TODO application with a Flutter frontend and planned Python FastAPI backend. The project is designed for mobile platforms (iOS/Android) using Flutter for cross-platform development.

## Architecture

- **Frontend**: Flutter application located in `frontend/`
- **Backend**: Python FastAPI (planned, not yet implemented in `backend/`)
- **Database**: PostgreSQL (planned)
- **Deployment**: Docker & Docker Compose (planned)

## Development Commands

### Flutter Frontend (in `frontend/` directory)

```bash
# Install dependencies
flutter pub get

# Run the app in development mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for release
flutter build apk       # Android
flutter build ios       # iOS

# Run tests
flutter test

# Analyze code
flutter analyze

# Clean build files
flutter clean
```

### Common Flutter Development Tasks

- **Hot Reload**: Press `r` in the terminal when running `flutter run`
- **Hot Restart**: Press `R` in the terminal when running `flutter run`
- **List available devices**: `flutter devices`
- **Create new widget**: Follow the existing patterns in `lib/main.dart`

## Code Structure

### Frontend (`frontend/`)
- `lib/main.dart` - Main application entry point with basic Flutter counter app
- `pubspec.yaml` - Flutter dependencies and configuration
- `analysis_options.yaml` - Dart analyzer configuration with flutter_lints
- Platform-specific code in `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`

### Backend (`backend/`)
- Currently empty directory - FastAPI implementation planned
- Will contain Python API server for task management

## Project Requirements

Based on `todo_app_requirements.md`, this project implements:
- Task creation, editing, deletion
- Task completion status management
- REST API endpoints (planned):
  - `GET /api/tasks` - List all tasks
  - `POST /api/tasks` - Create new task
  - `GET /api/tasks/{id}` - Get specific task
  - `PUT /api/tasks/{id}` - Update task
  - `DELETE /api/tasks/{id}` - Delete task

## Dependencies

### Flutter
- SDK: ^3.7.2
- flutter_lints: ^5.0.0 (for code analysis)
- cupertino_icons: ^1.0.8

### Backend (Planned)
- Python 3.9+
- FastAPI
- PostgreSQL 15+
- Docker & Docker Compose

## Testing

- Flutter tests: `flutter test`
- Test files located in `frontend/test/`
- Current test file: `widget_test.dart`

## Linting and Code Quality

- Uses `package:flutter_lints/flutter.yaml` for Dart/Flutter linting
- Run `flutter analyze` to check code quality
- Configuration in `frontend/analysis_options.yaml`