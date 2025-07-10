from pydantic_settings import BaseSettings
from typing import List, Optional, Union
from functools import lru_cache
from pydantic import field_validator, ValidationError
import os
import json
import logging

# ロギング設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
    
    @field_validator('cors_origins', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        """CORS_ORIGINS環境変数の安全な解析"""
        if isinstance(v, list):
            return v
        
        if isinstance(v, str):
            # 空文字列の場合はデフォルト値を使用
            if not v.strip():
                logger.warning("CORS_ORIGINS環境変数が空です。デフォルト値を使用します。")
                return ["*"]
            
            # JSON形式の文字列を解析
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return parsed
                else:
                    logger.warning(f"CORS_ORIGINS環境変数が配列ではありません: {v}")
                    return ["*"]
            except json.JSONDecodeError as e:
                logger.warning(f"CORS_ORIGINS環境変数のJSON解析に失敗しました: {v}, エラー: {e}")
                # カンマ区切り文字列として解析を試行
                try:
                    origins = [origin.strip() for origin in v.split(',')]
                    return [origin for origin in origins if origin]
                except Exception:
                    logger.error(f"CORS_ORIGINS環境変数の解析に完全に失敗しました: {v}")
                    return ["*"]
        
        # その他の型の場合はデフォルト値
        logger.warning(f"CORS_ORIGINS環境変数が予期しない型です: {type(v)}")
        return ["*"]
    
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
    try:
        return settings_class()
    except ValidationError as e:
        logger.error(f"設定の検証に失敗しました: {e}")
        # フォールバック設定
        logger.info("デフォルト設定を使用します。")
        return Settings()

# グローバル設定インスタンス
settings = get_settings()