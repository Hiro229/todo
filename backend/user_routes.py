from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
import schemas
import crud
from auth import create_user_token, get_current_user
from database import get_db
from config.settings import settings

router = APIRouter(tags=["authentication"])

@router.post("/register", response_model=schemas.AuthResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """新規ユーザー登録"""
    
    # 既存ユーザーの確認（メールアドレス）
    existing_user = crud.get_user_by_email(db, email=user.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # 既存ユーザーの確認（ユーザー名）
    existing_user = crud.get_user_by_username(db, username=user.username)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    try:
        # ユーザー作成
        db_user = crud.create_user(db=db, user=user)
        
        # JWTトークン作成
        access_token = create_user_token(user_id=db_user.id)
        
        # 最終ログイン時刻を更新
        crud.update_user_last_login(db, db_user.id)
        
        return schemas.AuthResponse(
            message="User registered successfully",
            user=schemas.UserProfile.model_validate(db_user),
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.access_token_expire_hours * 3600
        )
        
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User registration failed due to database constraint"
        )

@router.post("/login", response_model=schemas.AuthResponse)
def login_user(user_login: schemas.UserLogin, db: Session = Depends(get_db)):
    """ユーザーログイン"""
    
    # ユーザー認証
    user = crud.authenticate_user(db, email=user_login.email, password=user_login.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # JWTトークン作成
    access_token = create_user_token(user_id=user.id)
    
    # 最終ログイン時刻を更新
    crud.update_user_last_login(db, user.id)
    
    return schemas.AuthResponse(
        message="Login successful",
        user=schemas.UserProfile.model_validate(user),
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_hours * 3600
    )

@router.get("/me", response_model=schemas.UserProfile)
def get_current_user_profile(current_user: schemas.User = Depends(get_current_user)):
    """現在のユーザープロフィールを取得"""
    return schemas.UserProfile.model_validate(current_user)

@router.put("/me", response_model=schemas.UserProfile)
def update_current_user_profile(
    user_update: schemas.UserUpdate,
    current_user: schemas.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """現在のユーザープロフィールを更新"""
    
    # メールアドレスが変更される場合、重複チェック
    if user_update.email and user_update.email != current_user.email:
        existing_user = crud.get_user_by_email(db, email=user_update.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # ユーザー名が変更される場合、重複チェック
    if user_update.username and user_update.username != current_user.username:
        existing_user = crud.get_user_by_username(db, username=user_update.username)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    try:
        updated_user = crud.update_user(db, user_id=current_user.id, user_update=user_update)
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return schemas.UserProfile.model_validate(updated_user)
        
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Update failed due to database constraint"
        )

@router.post("/verify-token", response_model=schemas.UserProfile)
def verify_user_token(current_user: schemas.User = Depends(get_current_user)):
    """トークンを検証してユーザー情報を返す"""
    return schemas.UserProfile.model_validate(current_user)