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

### Full Stack Development

```bash
# Start backend and database services
docker-compose up -d

# Check API health
curl http://localhost:8000/

# Stop services
docker-compose down

# Reset database (remove volumes)
docker-compose down -v
```

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

### Backend Development (in `backend/` directory)

```bash
# Run locally without Docker
pip install -r requirements.txt
uvicorn main:app --reload

# Check logs
docker-compose logs backend

# Access database
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
- **iOS Simulator**: Uses `localhost:8000`
- **Android Emulator**: Uses `10.0.2.2:8000`
- **Physical Device**: Needs manual IP configuration

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