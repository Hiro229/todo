from fastapi import Request, HTTPException, status
from fastapi.responses import Response
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import time
from typing import Dict, Any
import os

# レート制限の設定
limiter = Limiter(key_func=get_remote_address)

# セキュリティヘッダーミドルウェア
async def add_security_headers(request: Request, call_next):
    """セキュリティヘッダーを追加するミドルウェア"""
    response: Response = await call_next(request)
    
    # セキュリティヘッダーを追加
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    
    return response

# リクエストサイズ制限ミドルウェア
async def limit_upload_size(request: Request, call_next):
    """リクエストサイズを制限するミドルウェア"""
    content_length = request.headers.get("content-length")
    if content_length:
        content_length = int(content_length)
        max_size = 1024 * 1024  # 1MB
        if content_length > max_size:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Request entity too large"
            )
    
    response = await call_next(request)
    return response

# レート制限のカスタムエラーハンドラー
def custom_rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """カスタムレート制限エラーハンドラー"""
    response = HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail={
            "error": "Rate limit exceeded",
            "message": f"Too many requests. Retry after {exc.retry_after} seconds.",
            "retry_after": exc.retry_after
        }
    )
    return response

# 入力値検証関数
def validate_string_input(value: str, max_length: int = 255, field_name: str = "field") -> str:
    """文字列入力値を検証"""
    if not value or len(value.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{field_name} cannot be empty"
        )
    
    if len(value) > max_length:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{field_name} cannot exceed {max_length} characters"
        )
    
    # 基本的なXSS対策（HTMLタグを除去）
    import re
    cleaned_value = re.sub(r'<[^>]*>', '', value)
    return cleaned_value.strip()

def validate_task_data(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """タスクデータを検証"""
    validated_data = {}
    
    if "title" in task_data:
        validated_data["title"] = validate_string_input(
            task_data["title"], 
            max_length=255, 
            field_name="title"
        )
    
    if "description" in task_data and task_data["description"]:
        validated_data["description"] = validate_string_input(
            task_data["description"], 
            max_length=1000, 
            field_name="description"
        )
    
    if "priority" in task_data:
        priority = task_data["priority"]
        if not isinstance(priority, int) or priority < 1 or priority > 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Priority must be 1 (High), 2 (Medium), or 3 (Low)"
            )
        validated_data["priority"] = priority
    
    return validated_data

def validate_category_data(category_data: Dict[str, Any]) -> Dict[str, Any]:
    """カテゴリデータを検証"""
    validated_data = {}
    
    if "name" in category_data:
        validated_data["name"] = validate_string_input(
            category_data["name"], 
            max_length=100, 
            field_name="name"
        )
    
    if "color" in category_data and category_data["color"]:
        color = category_data["color"]
        # 色コードの形式を検証（#RRGGBB）
        import re
        if not re.match(r'^#[0-9A-Fa-f]{6}$', color):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Color must be in hex format (#RRGGBB)"
            )
        validated_data["color"] = color
    
    return validated_data