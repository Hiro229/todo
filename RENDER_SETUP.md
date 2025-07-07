# Render Production Setup Guide

## Render Environment Variables Configuration

When deploying to Render, set the following environment variables in the Render Dashboard:

### Required Environment Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `ENVIRONMENT` | `production` | Environment identifier |
| `DEBUG` | `false` | Disable debug mode |
| `DATABASE_URL` | `postgresql://todo_user:[PASSWORD]@dpg-d1ks3615pdvs73b82g7g-a:5432/todo_db_22qu` | Full database connection string |
| `JWT_SECRET_KEY` | `[GENERATE_SECURE_KEY]` | 256-bit random secret key |
| `JWT_ALGORITHM` | `HS256` | JWT signing algorithm |
| `ACCESS_TOKEN_EXPIRE_HOURS` | `12` | Token expiration time |
| `APP_NAME` | `TODO App API` | Application name |
| `APP_VERSION` | `4.0.0` | Application version |
| `HOST` | `0.0.0.0` | Bind to all interfaces |
| `PORT` | `$PORT` | Render-provided port |
| `CORS_ORIGINS` | `["https://todo-app-frontend.onrender.com"]` | Allowed CORS origins |
| `CORS_ALLOW_CREDENTIALS` | `true` | Allow credentials |
| `MAX_REQUEST_SIZE` | `1048576` | 1MB request limit |
| `RATE_LIMIT_AUTH` | `5/minute` | Auth endpoint rate limit |
| `RATE_LIMIT_API` | `50/minute` | API endpoint rate limit |

### Database Connection Details (From Render Dashboard)

```
Hostname: dpg-d1ks3615pdvs73b82g7g-a
Port: 5432
Database: todo_db_22qu
Username: todo_user
Password: [OBTAIN_FROM_RENDER_DASHBOARD]
Internal Database URL: [OBTAIN_FROM_RENDER_DASHBOARD]
External Database URL: [OBTAIN_FROM_RENDER_DASHBOARD]
PSQL Command: [OBTAIN_FROM_RENDER_DASHBOARD]
```

### Steps to Configure Render

1. **Create PostgreSQL Database**:
   - Go to Render Dashboard
   - Create new PostgreSQL service
   - Note down the connection details

2. **Create Web Service**:
   - Connect to GitHub repository
   - Set build command: `cd backend && pip install -r requirements.txt`
   - Set start command: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`

3. **Set Environment Variables**:
   - In the web service settings, add all variables from the table above
   - **Important**: Replace placeholder values with actual values from Render dashboard

4. **Generate JWT Secret Key**:
   ```bash
   # Generate a secure 256-bit key
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

5. **Update CORS Origins**:
   - Replace `https://todo-app-frontend.onrender.com` with your actual frontend URL
   - For development, you can temporarily use `["*"]` but change for production

6. **Deploy**:
   - Push changes to main branch
   - Render will automatically deploy

### Security Checklist

- [ ] JWT secret key is at least 256 bits and randomly generated
- [ ] Database password is obtained from Render (never hardcoded)
- [ ] CORS origins are set to specific domains (not wildcard "*")
- [ ] Debug mode is disabled (`DEBUG=false`)
- [ ] Rate limiting is enabled
- [ ] All sensitive values are in Render environment variables, not in code

### Accessing Database

To connect to the production database:

1. Get the PSQL command from Render dashboard
2. Use it to connect directly:
   ```bash
   psql [PSQL_COMMAND_FROM_RENDER]
   ```

### Health Check

After deployment, verify the service is running:

```bash
curl https://[YOUR_RENDER_URL]/health
```

Expected response:
```json
{
  "status": "healthy",
  "environment": "production",
  "version": "4.0.0",
  "timestamp": "2025-07-06T12:00:00Z"
}
```

### Troubleshooting

1. **Database Connection Issues**:
   - Verify `DATABASE_URL` in environment variables
   - Check that database service is running
   - Ensure network connectivity between services

2. **JWT Authentication Issues**:
   - Verify `JWT_SECRET_KEY` is set and secure
   - Check token expiration settings
   - Validate CORS configuration

3. **CORS Errors**:
   - Update `CORS_ORIGINS` with correct frontend URL
   - Ensure format is correct: `["https://domain.com"]`

4. **Rate Limiting Issues**:
   - Adjust rate limits if needed
   - Check if rates are appropriate for your use case

### Monitoring

- Check Render logs for any errors
- Monitor database connections
- Watch for rate limiting violations
- Monitor JWT token usage patterns