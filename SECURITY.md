# Security Guidelines

## Overview

This document outlines the security measures implemented in the TODO application and provides guidelines for maintaining security across all environments.

## Sensitive Files and Git Security

### Files Excluded from Git

The following files contain sensitive information and are automatically excluded from version control via `.gitignore`:

#### Environment Files
- `.env*` - All environment variable files
- `backend/.env*` - Backend-specific environment files
- `frontend/.env*` - Frontend-specific environment files
- `.env.render-production` - Render production configuration

#### Deployment Files
- `render.production.yaml` - Production Render configuration
- `render-secrets.env` - Render secrets

#### Security Files
- `*.pem`, `*.key`, `*.crt` - Certificates and private keys
- `secrets/`, `credentials/` - Any secrets directories
- `docker-secrets/`, `k8s-secrets/` - Container secrets

### ⚠️ NEVER Commit These

- Database passwords
- JWT secret keys
- API keys
- SSL certificates
- Production URLs
- User credentials

## Environment-Specific Security

### Development Environment
- **JWT Secret**: Development-only key (weak but acceptable)
- **CORS**: Wildcard allowed (`*`)
- **Debug Mode**: Enabled
- **Rate Limiting**: Relaxed (10/minute auth, 100/minute API)
- **HTTPS**: Not required locally

### Staging Environment
- **JWT Secret**: Secure generated key
- **CORS**: Specific staging domains only
- **Debug Mode**: Disabled
- **Rate Limiting**: Production-like (10/minute auth, 100/minute API)
- **HTTPS**: Required

### Production Environment
- **JWT Secret**: Cryptographically secure key (256+ bits)
- **CORS**: Strict domain whitelist
- **Debug Mode**: Disabled
- **Rate Limiting**: Strict (5/minute auth, 50/minute API)
- **HTTPS**: Required with security headers

## JWT Token Security

### Requirements
- **Algorithm**: HS256 only
- **Secret Key**: Minimum 256 bits, randomly generated
- **Expiration**: 12 hours maximum
- **Storage**: Flutter Secure Storage with encryption

### Key Generation
```bash
# Generate secure JWT secret
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Validation
- Signature verification
- Expiration time checking
- Algorithm verification
- Issuer/audience validation

## Database Security

### Render PostgreSQL Configuration
- **Hostname**: `dpg-d1ks3615pdvs73b82g7g-a` (internal)
- **Database**: `todo_db_22qu`
- **Username**: `todo_user`
- **Password**: [NEVER COMMIT - GET FROM RENDER DASHBOARD]

### Access Control
- Database credentials stored in environment variables only
- Connection strings never hardcoded
- Use connection pooling in production
- Regular credential rotation

## API Security

### Rate Limiting
```python
# Production rates
AUTH_ENDPOINTS = "5/minute"
API_ENDPOINTS = "50/minute"

# Development rates  
AUTH_ENDPOINTS = "10/minute"
API_ENDPOINTS = "100/minute"
```

### Security Headers
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security`
- `Content-Security-Policy`

### Input Validation
- All input sanitized and validated
- SQL injection prevention via parameterized queries
- XSS protection via output encoding
- Request size limits (1MB)

## CORS Configuration

### Development
```python
CORS_ORIGINS = ["*"]  # Acceptable for local development
```

### Production
```python
CORS_ORIGINS = ["https://todo-app-frontend.onrender.com"]  # Specific domains only
```

## Deployment Security

### Environment Variables
Never set sensitive values directly in:
- Docker Compose files
- Kubernetes manifests  
- CI/CD pipeline files
- Source code

Always use:
- Render environment variables
- Docker secrets
- Kubernetes secrets
- CI/CD secret management

### Render Deployment
1. **Manual Setup**: Set sensitive values in Render dashboard
2. **Generated Values**: Use `generateValue: true` for JWT secrets
3. **Database URLs**: Use Render's automatic injection
4. **Validation**: Always test with staging environment first

## Monitoring and Incident Response

### Security Monitoring
- Failed authentication attempts
- Rate limit violations
- Unusual traffic patterns
- Database connection anomalies

### Incident Response
1. **Immediate**: Rotate compromised credentials
2. **Short-term**: Analyze logs and impact
3. **Long-term**: Improve security measures

## Security Checklist

### Pre-Deployment
- [ ] All sensitive files are in `.gitignore`
- [ ] Environment variables are set correctly
- [ ] JWT secret is secure and unique per environment
- [ ] CORS origins are environment-appropriate
- [ ] Rate limiting is configured
- [ ] Debug mode is disabled in production
- [ ] HTTPS is enforced
- [ ] Database credentials are secure

### Post-Deployment
- [ ] Health check endpoint responds correctly
- [ ] Authentication works as expected
- [ ] Rate limiting is effective
- [ ] CORS policy is enforced
- [ ] Security headers are present
- [ ] No sensitive data in logs

### Regular Maintenance
- [ ] Rotate JWT secrets quarterly
- [ ] Update dependencies regularly
- [ ] Review access logs monthly
- [ ] Audit environment variables
- [ ] Test backup and recovery procedures

## Contact and Reporting

For security issues or questions:
1. Review this documentation
2. Check environment-specific configurations
3. Verify against security checklist
4. Test in staging before production

## Additional Resources

- [OWASP Security Guidelines](https://owasp.org/)
- [JWT Security Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
- [Render Security Documentation](https://render.com/docs/security)
- [FastAPI Security Documentation](https://fastapi.tiangolo.com/tutorial/security/)