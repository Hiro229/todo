from fastapi import HTTPException, Depends, Header
from sqlalchemy.orm import Session
from typing import Optional
import crud
from database import SessionLocal

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_api_key_from_header(x_api_key: Optional[str] = Header(None)) -> str:
    """ヘッダーからAPI keyを取得"""
    if not x_api_key:
        raise HTTPException(
            status_code=401,
            detail="API key is required. Please provide X-API-Key header."
        )
    return x_api_key

def verify_api_key(
    api_key: str = Depends(get_api_key_from_header),
    db: Session = Depends(get_db)
):
    """API keyを検証"""
    db_api_key = crud.verify_api_key(db, api_key)
    if not db_api_key:
        raise HTTPException(
            status_code=401,
            detail="Invalid or inactive API key"
        )
    return db_api_key

# オプション: API key認証を無効にした依存関数
def optional_api_key_auth(
    x_api_key: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    """オプショナルなAPI key認証（開発用）"""
    if x_api_key:
        db_api_key = crud.verify_api_key(db, x_api_key)
        if not db_api_key:
            raise HTTPException(
                status_code=401,
                detail="Invalid or inactive API key"
            )
        return db_api_key
    return None