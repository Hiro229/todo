# Environment Setup Guide

This guide explains how to set up and deploy the TODO application across different environments.

## Environments

### 1. Development Environment (Local)
- **Purpose**: Local development and testing
- **Infrastructure**: Docker Compose
- **Database**: PostgreSQL (Docker container)
- **API**: FastAPI with hot reload
- **Frontend**: Flutter with hot reload

### 2. Staging Environment (Render)
- **Purpose**: Testing before production deployment
- **Infrastructure**: Render Web Service + Render PostgreSQL
- **Database**: Render PostgreSQL
- **API**: FastAPI on Render
- **Frontend**: Flutter Web (future)

### 3. Production Environment
- **Purpose**: Live application
- **Infrastructure**: Render/AWS (configurable)
- **Database**: Managed PostgreSQL
- **API**: FastAPI with optimized Docker container
- **Frontend**: Flutter Web/Mobile apps

## Quick Start

### Development Environment

1. **Clone and setup**:
```bash
git clone <repository>
cd todo
```

2. **Start with Docker Compose**:
```bash
# Using default development environment
docker-compose up -d

# Or with custom environment variables
ENVIRONMENT=development docker-compose up -d
```

3. **Test the setup**:
```bash
curl http://localhost:8000/health
```

### Staging Environment (Render)

1. **Deploy to Render**:
```bash
# Render will automatically deploy using render.yaml
git push origin main
```

2. **Environment Variables** (Set in Render Dashboard):
- `ENVIRONMENT=staging`
- `JWT_SECRET_KEY=<generated-secret>`
- `DATABASE_URL` (auto-generated by Render)

### Production Environment

1. **Deploy with production Docker Compose**:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

2. **Or deploy to cloud provider** using the production Dockerfile.

## Environment Configuration

### Backend Configuration

Environment-specific settings are managed through:
- **Settings Class**: `backend/config/settings.py`
- **Environment Files**: `.env.{environment}`
- **Environment Variables**: Override any setting

#### Configuration Hierarchy:
1. Environment variables (highest priority)
2. Environment-specific `.env` files
3. Default values in settings class

#### Key Settings:
```python
# Development
DATABASE_URL=postgresql://postgres:password@db:5432/todoapp
JWT_SECRET_KEY=dev-secret-key
DEBUG=true
CORS_ORIGINS=*

# Staging
DATABASE_URL=${DATABASE_URL}  # From Render
JWT_SECRET_KEY=${JWT_SECRET_KEY}  # From Render env vars
DEBUG=false
CORS_ORIGINS=https://todo-app-frontend-staging.onrender.com

# Production
DATABASE_URL=${DATABASE_URL}  # From cloud provider
JWT_SECRET_KEY=${JWT_SECRET_KEY}  # From secure env vars
DEBUG=false
CORS_ORIGINS=https://todo-app.example.com
```

### Frontend Configuration

Environment-specific settings are managed through:
- **AppConfig Class**: `frontend/lib/config/app_config.dart`
- **Compile-time Constants**: `--dart-define=FLUTTER_ENV=environment`
- **Build Scripts**: `frontend/scripts/build_*.sh`

#### Environment Detection:
```dart
// Set environment at compile time
flutter build apk --dart-define=FLUTTER_ENV=staging

// Environment-specific API URLs
- Development: http://localhost:8000 (iOS) / http://10.0.2.2:8000 (Android)
- Staging: https://todo-app-api-staging.onrender.com
- Production: https://api.todo-app.example.com
```

## Build and Deployment

### Backend

#### Development:
```bash
# Local development with hot reload
cd backend
uvicorn main:app --reload

# Or with Docker
docker-compose up backend
```

#### Staging/Production:
```bash
# Build optimized Docker image
docker build -f backend/Dockerfile -t todo-backend:prod backend/

# Deploy to Render (automatic via Git push)
git push origin main
```

### Frontend

#### Development:
```bash
cd frontend
flutter run  # Automatically uses development config
```

#### Staging:
```bash
cd frontend
./scripts/build_staging.sh
```

#### Production:
```bash
cd frontend
./scripts/build_production.sh
```

## Environment Variables

### Required Environment Variables

#### Backend:
```bash
# Required in all environments
DATABASE_URL=postgresql://user:password@host:port/database
JWT_SECRET_KEY=your-secret-key-256-bits-minimum

# Environment-specific
ENVIRONMENT=development|staging|production
DEBUG=true|false
CORS_ORIGINS=comma-separated-list-of-origins
```

#### Frontend (Compile-time):
```bash
# Set during build
FLUTTER_ENV=development|staging|production
```

### Setting Environment Variables

#### Development (Local):
- Create `.env.development` in backend directory
- Use Docker Compose environment variables

#### Staging (Render):
- Set in Render Dashboard under "Environment"
- Automatically configured via `render.yaml`

#### Production:
- Set in cloud provider's environment variable system
- Use secure secret management services

## Database Migration

### Development:
```bash
# Database is recreated on container restart
docker-compose down -v  # Removes all data
docker-compose up -d
```

### Staging/Production:
```bash
# Run migrations (when implemented)
cd backend
alembic upgrade head
```

## Monitoring and Health Checks

### Health Check Endpoints:
- **Backend**: `GET /health`
- **Database**: Built-in Docker health checks

### Example Health Check:
```bash
# Development
curl http://localhost:8000/health

# Staging
curl https://todo-app-api-staging.onrender.com/health

# Production
curl https://api.todo-app.example.com/health
```

## Troubleshooting

### Common Issues:

1. **Database Connection Failed**:
   - Check `DATABASE_URL` environment variable
   - Ensure PostgreSQL is running
   - Verify network connectivity

2. **JWT Authentication Failed**:
   - Check `JWT_SECRET_KEY` is set
   - Verify token hasn't expired
   - Check client-server time sync

3. **CORS Errors**:
   - Verify `CORS_ORIGINS` includes your frontend URL
   - Check environment-specific settings

4. **Build Failures**:
   - Run `flutter clean && flutter pub get`
   - Check Flutter SDK version compatibility
   - Verify all dependencies are available

### Logs:

#### Development:
```bash
# Backend logs
docker-compose logs backend

# Database logs
docker-compose logs db
```

#### Staging/Production:
- Check Render Dashboard logs
- Use cloud provider logging services

## Security Considerations

### Development:
- Uses weak JWT secret (acceptable for dev)
- All CORS origins allowed
- Debug mode enabled

### Staging:
- Strong JWT secret from environment
- Specific CORS origins
- Debug mode disabled
- HTTPS enforced

### Production:
- Strong JWT secret from secure storage
- Strict CORS policy
- All debug features disabled
- HTTPS enforced
- Rate limiting enabled
- Security headers configured

## File Structure

```
todo/
├── backend/
│   ├── config/
│   │   └── settings.py          # Environment configuration
│   ├── .env.development         # Development settings
│   ├── .env.staging            # Staging settings
│   ├── .env.production         # Production settings
│   ├── Dockerfile              # Production Dockerfile
│   └── Dockerfile.dev          # Development Dockerfile
├── frontend/
│   ├── lib/config/
│   │   └── app_config.dart     # Environment configuration
│   └── scripts/
│       ├── build_dev.sh        # Development build
│       ├── build_staging.sh    # Staging build
│       └── build_production.sh # Production build
├── docker-compose.yml          # Development Docker Compose
├── docker-compose.prod.yml     # Production Docker Compose
├── render.yaml                 # Render deployment config
└── .github/workflows/
    └── deploy-staging.yml      # GitHub Actions CI/CD
```