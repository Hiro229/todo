from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import secrets
import os
from config.settings import settings
import crud
from database import get_db

# JWT設定
SECRET_KEY = settings.jwt_secret_key
ALGORITHM = settings.jwt_algorithm
ACCESS_TOKEN_EXPIRE_HOURS = settings.access_token_expire_hours

# HTTPBearer認証スキーム
security = HTTPBearer()

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """JWTアクセストークンを作成"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.utcnow(),
        "type": "access"
    })
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> dict:
    """JWTトークンを検証してペイロードを返す"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        # 有効期限チェック
        exp = payload.get("exp")
        if exp is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token missing expiration",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # トークンタイプチェック
        token_type = payload.get("type")
        if token_type != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), 
                     db: Session = Depends(get_db)):
    """現在のユーザーを取得"""
    token = credentials.credentials
    payload = verify_token(token)
    
    user_id = payload.get("user_id")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = crud.get_user_by_id(db, user_id=user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user

def get_current_session(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """現在のセッション情報を取得（下位互換性のため残す）"""
    token = credentials.credentials
    payload = verify_token(token)
    
    session_id = payload.get("session_id")
    if session_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return {
        "session_id": session_id,
        "issued_at": payload.get("iat"),
        "expires_at": payload.get("exp")
    }

def create_user_token(user_id: int) -> str:
    """ユーザー用のJWTトークンを作成"""
    token_data = {
        "user_id": user_id,
        "auth_type": "user"
    }
    
    access_token = create_access_token(data=token_data)
    return access_token

def create_session_token() -> tuple[str, str]:
    """新しいセッションIDとトークンを作成（下位互換性のため残す）"""
    session_id = secrets.token_urlsafe(32)
    
    token_data = {
        "session_id": session_id,
        "auth_type": "simple"
    }
    
    access_token = create_access_token(data=token_data)
    return session_id, access_token