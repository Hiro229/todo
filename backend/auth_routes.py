from fastapi import APIRouter, Depends, HTTPException, status, Request
from datetime import datetime, timedelta
from typing import Dict, Any
from auth import create_session_token, get_current_session, ACCESS_TOKEN_EXPIRE_HOURS
from pydantic import BaseModel
from security import limiter

router = APIRouter(prefix="/auth", tags=["authentication"])

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

class AuthStatusResponse(BaseModel):
    authenticated: bool
    session_id: str
    expires_at: int
    issued_at: int

@router.post("/simple", response_model=TokenResponse)
@limiter.limit("10/minute")
async def simple_auth(request: Request):
    """シンプル認証 - 自動的にセッションを作成してJWTトークンを返す"""
    try:
        session_id, access_token = create_session_token()
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=ACCESS_TOKEN_EXPIRE_HOURS * 3600  # 秒単位
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create authentication token"
        )

@router.get("/verify", response_model=AuthStatusResponse)
@limiter.limit("20/minute")
async def verify_auth(
    request: Request, 
    session_info: Dict[str, Any] = Depends(get_current_session)
):
    """認証状態確認 - 現在のトークンの有効性を確認"""
    return AuthStatusResponse(
        authenticated=True,
        session_id=session_info["session_id"],
        expires_at=session_info["expires_at"],
        issued_at=session_info["issued_at"]
    )