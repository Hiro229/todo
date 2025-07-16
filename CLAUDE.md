# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a TODO application with a Flutter frontend and Python FastAPI backend. The project is designed for mobile platforms (iOS/Android) using Flutter for cross-platform development, featuring task management with categories, priorities, and advanced filtering capabilities.

## Architecture

- **Frontend**: Flutter application in `frontend/` with full task management UI
- **Backend**: Python FastAPI server in `backend/` with full CRUD operations
- **Database**: PostgreSQL with Docker Compose for development
- **Deployment**: Docker Compose for development, plans for Render/AWS for production

## Development Commands

### 環境設定

#### 本番環境（Production）
```bash
# Flutter - 本番環境用ビルド
flutter build apk --dart-define=FLUTTER_ENV=production
flutter build ios --dart-define=FLUTTER_ENV=production

# Backend - 本番環境設定
export ENVIRONMENT=production
```

#### 開発環境（Development）
```bash
# Flutter - 開発環境用実行
flutter run --dart-define=FLUTTER_ENV=development

# Backend - 開発環境設定
export ENVIRONMENT=development
```

### Full Stack Development

```bash
# 開発環境: Start backend and database services
docker-compose up -d

# 本番環境: Check API health (Render)
curl https://todo-2ui9.onrender.com/

# 開発環境: Stop services
docker-compose down

# 開発環境: Reset database (remove volumes)
docker-compose down -v
```

### Flutter Frontend (in `frontend/` directory)

```bash
# Install dependencies
flutter pub get

# 開発環境: Run the app in development mode
flutter run --dart-define=FLUTTER_ENV=development

# 本番環境: Run the app in production mode
flutter run --dart-define=FLUTTER_ENV=production

# Run on specific device
flutter run -d <device_id>

# Build for release
flutter build apk --dart-define=FLUTTER_ENV=production       # Android
flutter build ios --dart-define=FLUTTER_ENV=production       # iOS

# Run tests
flutter test

# Analyze code
flutter analyze

# Clean build files
flutter clean
```

### Backend Development (in `backend/` directory)

```bash
# 開発環境: Run locally without Docker
pip install -r requirements.txt
ENVIRONMENT=development uvicorn main:app --reload

# 本番環境: Run in production mode
ENVIRONMENT=production uvicorn main:app --host 0.0.0.0 --port 8000

# 開発環境: Check logs
docker-compose logs backend

# 開発環境: Access database
docker-compose exec db psql -U postgres -d todoapp
```

## API Endpoints

The backend provides full REST API for tasks and categories:

### Task Management
- `GET /api/tasks` - Get all tasks with optional filtering (search, category_id, priority, is_completed)
- `POST /api/tasks` - Create new task
- `GET /api/tasks/{id}` - Get specific task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

### Category Management
- `GET /api/categories` - Get all categories
- `POST /api/categories` - Create new category
- `GET /api/categories/{id}` - Get specific category
- `PUT /api/categories/{id}` - Update category
- `DELETE /api/categories/{id}` - Delete category

## Code Structure

### Frontend (`frontend/`)
- `lib/main.dart` - Main application entry point
- `lib/models/task.dart` - Task and Category data models with Priority enum
- `lib/services/api_service.dart` - API service layer with platform-specific URLs
- `lib/screens/` - UI screens for task management
- `pubspec.yaml` - Flutter dependencies including http and intl packages

### Backend (`backend/`)
- `main.py` - FastAPI app with CORS middleware and all endpoints
- `models.py` - SQLAlchemy models for Task and Category with relationships
- `schemas.py` - Pydantic schemas for request/response validation
- `crud.py` - Database operations for tasks and categories
- `database.py` - Database connection and session management
- `requirements.txt` - Python dependencies

## Database Schema

### Tasks Table
- `id` (Primary Key)
- `title` (VARCHAR(255), NOT NULL)
- `description` (TEXT)
- `is_completed` (BOOLEAN, default: FALSE)
- `priority` (INTEGER, default: 2) - 1=High, 2=Medium, 3=Low
- `due_date` (DATETIME)
- `category_id` (Foreign Key to categories.id)
- `created_at`, `updated_at` (Auto-managed timestamps)

### Categories Table
- `id` (Primary Key)
- `name` (VARCHAR(100), UNIQUE, NOT NULL)
- `color` (VARCHAR(7)) - Hex color code
- `created_at` (Auto-managed timestamp)

## Dependencies

### Flutter
- SDK: ^3.7.2
- http: ^1.1.0 (API communication)
- intl: ^0.18.1 (Date formatting)
- flutter_lints: ^5.0.0 (Code analysis)

### Backend
- fastapi==0.104.1
- uvicorn==0.24.0
- sqlalchemy==2.0.23
- psycopg2-binary==2.9.9 (PostgreSQL driver)
- pydantic==2.4.2
- alembic==1.13.1 (Database migrations)

## Testing

- Flutter tests: `flutter test`
- Test files located in `frontend/test/`
- Backend has no test files yet

## Linting and Code Quality

- Flutter: `flutter analyze` using `flutter_lints`
- Backend: No linting configured yet

## Platform-Specific Notes

### Flutter API Configuration

#### 開発環境 (Development)
- **iOS Simulator**: Uses `localhost:8000`
- **Android Emulator**: Uses `10.0.2.2:8000`
- **Physical Device**: Uses automatic IP detection or manual configuration

#### 本番環境 (Production)
- **All Platforms**: Uses `https://todo-2ui9.onrender.com` (Render deployment)

### Environment Variables

#### Flutter Environment Variables
```bash
# 開発環境
FLUTTER_ENV=development

# 本番環境
FLUTTER_ENV=production

# 開発環境のカスタムサーバーIP（オプション）
DEV_SERVER_HOST=192.168.1.100
```

#### Backend Environment Variables
```bash
# 開発環境
ENVIRONMENT=development
DATABASE_URL=postgresql://postgres:password@db:5432/todoapp

# 本番環境
ENVIRONMENT=production
DATABASE_URL=postgresql://[user]:[password]@[host]:[port]/[database]
JWT_SECRET_KEY=your-production-secret-key
```

### Docker Environment
- PostgreSQL runs on port 5432
- FastAPI runs on port 8000
- Database: `todoapp` with user `postgres:password`

## Current Implementation Status

This project is fully functional with:
- ✅ Complete task CRUD operations
- ✅ Category management system
- ✅ Priority levels (High/Medium/Low)
- ✅ Task filtering and search
- ✅ Docker development environment
- ✅ Cross-platform Flutter app
- ✅ RESTful API with proper validation

## Future Enhancements (from requirements)

- JWT authentication system
- User management
- Environment-specific configurations
- Production deployment (Render/AWS)
- Advanced security features