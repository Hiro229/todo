from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import IntEnum

class Priority(IntEnum):
    HIGH = 1
    MEDIUM = 2
    LOW = 3

class ApiKeyBase(BaseModel):
    name: Optional[str] = None

class ApiKeyCreate(ApiKeyBase):
    pass

class ApiKey(ApiKeyBase):
    id: int
    key_hash: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class ApiKeyResponse(BaseModel):
    id: int
    name: Optional[str] = None
    key: str  # 生成されたAPIキー（平文）
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

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