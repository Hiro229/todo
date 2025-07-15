from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
from typing import Optional, List
from enum import IntEnum

class Priority(IntEnum):
    HIGH = 1
    MEDIUM = 2
    LOW = 3

# ユーザー関連のスキーマ
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=3, max_length=100)
    full_name: Optional[str] = None
    password: Optional[str] = Field(None, min_length=8, max_length=100)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class User(UserBase):
    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserProfile(BaseModel):
    id: int
    email: str
    username: str
    full_name: Optional[str] = None
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True

# 認証応答スキーマ
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserProfile

class AuthResponse(BaseModel):
    message: str
    user: UserProfile
    access_token: str
    token_type: str = "bearer"
    expires_in: int

class CategoryBase(BaseModel):
    name: str
    color: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None

class Category(CategoryBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    priority: Optional[int] = Field(default=2, ge=1, le=3)
    due_date: Optional[datetime] = None
    category_id: Optional[int] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    is_completed: Optional[bool] = None
    priority: Optional[int] = Field(default=None, ge=1, le=3)
    due_date: Optional[datetime] = None
    category_id: Optional[int] = None

class Task(TaskBase):
    id: int
    is_completed: bool
    created_at: datetime
    updated_at: datetime
    category: Optional[Category] = None

    class Config:
        from_attributes = True