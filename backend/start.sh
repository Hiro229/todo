#!/bin/bash
set -e

echo "Starting TODO App Backend..."
echo "Environment: $ENVIRONMENT"
echo "Port: $PORT"

# Run database migrations if needed
echo "Running database migrations..."
alembic upgrade head

# Start the application
echo "Starting FastAPI server..."
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Starting with Gunicorn for production..."
    exec gunicorn main:app -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8000} --preload --max-requests 1000 --max-requests-jitter 50
else
    echo "Starting with Uvicorn for development..."
    exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --reload
fi