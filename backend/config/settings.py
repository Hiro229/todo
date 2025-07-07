from pydantic_settings import BaseSettings
from typing import List, Optional
from functools import lru_cache
import os

class Settings(BaseSettings):
    # 環境設定
    environment: str = "development"
    debug: bool = True
    
    # データベース設定
    database_url: str = "postgresql://postgres:password@localhost:5432/todoapp"
    
    # JWT設定
    jwt_secret_key: str = "your-super-secret-jwt-key-here-256-bits-minimum"
    jwt_algorithm: str = "HS256"
    access_token_expire_hours: int = 12
    
    # CORS設定
    cors_origins: List[str] = ["http://localhost:3000", "http://localhost:8080", "*"]
    cors_allow_credentials: bool = True
    cors_allow_methods: List[str] = ["*"]
    cors_allow_headers: List[str] = ["*"]
    
    # セキュリティ設定
    max_request_size: int = 1048576  # 1MB
    rate_limit_auth: str = "10/minute"
    rate_limit_api: str = "100/minute"
    
    # アプリケーション設定
    app_name: str = "TODO App API"
    app_version: str = "4.0.0"
    
    # Render固有設定
    port: int = 8000
    host: str = "0.0.0.0"
    
    class Config:
        env_file = f".env.{os.getenv('ENVIRONMENT', 'development')}"
        env_file_encoding = 'utf-8'
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields from environment

class DevelopmentSettings(Settings):
    """開発環境設定"""
    environment: str = "development"
    debug: bool = True
    database_url: str = "postgresql://postgres:password@db:5432/todoapp"
    cors_origins: List[str] = ["*"]  # 開発環境では全てのオリジンを許可

class StagingSettings(Settings):
    """検証環境設定（Render）"""
    environment: str = "staging"
    debug: bool = False
    cors_origins: List[str] = ["https://todo-app-frontend-staging.onrender.com"]
    
    class Config:
        env_file = ".env.staging"

class ProductionSettings(Settings):
    """本番環境設定"""
    environment: str = "production"
    debug: bool = False
    cors_origins: List[str] = ["https://todo-app.example.com"]
    
    class Config:
        env_file = ".env.production"

@lru_cache()
def get_settings() -> Settings:
    """環境に応じた設定を取得"""
    environment = os.getenv("ENVIRONMENT", "development").lower()
    
    settings_map = {
        "development": DevelopmentSettings,
        "staging": StagingSettings,
        "production": ProductionSettings,
    }
    
    settings_class = settings_map.get(environment, DevelopmentSettings)
    return settings_class()

# グローバル設定インスタンス
settings = get_settings()