from fastapi import FastAPI, HTTPException, Depends, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import models, schemas, crud, database
from database import SessionLocal, engine, get_db
from auth import get_current_session, get_current_user
from user_routes import router as user_router
from security import (
    limiter, 
    add_security_headers, 
    limit_upload_size,
    custom_rate_limit_handler
)
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from config.settings import settings

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug
)

# レート制限の設定
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, custom_rate_limit_handler)

# セキュリティミドルウェア
app.middleware("http")(add_security_headers)
app.middleware("http")(limit_upload_size)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
)


# 認証ルーターを登録
app.include_router(user_router, prefix="/auth")

@app.get("/")
def read_root():
    return {
        "message": f"{settings.app_name} v{settings.app_version} - Phase 4 Environment System",
        "environment": settings.environment,
        "debug": settings.debug
    }

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "environment": settings.environment,
        "version": settings.app_version,
        "timestamp": "2025-07-06T12:00:00Z"
    }

# Task endpoints
@app.get("/api/tasks", response_model=List[schemas.Task])
def get_tasks(
    search: Optional[str] = Query(None, description="検索キーワード"),
    category_id: Optional[int] = Query(None, description="カテゴリID"),
    priority: Optional[int] = Query(None, ge=1, le=3, description="優先度 (1=High, 2=Medium, 3=Low)"),
    is_completed: Optional[bool] = Query(None, description="完了状態"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """ユーザーのタスクを条件付きで取得"""
    tasks = crud.get_tasks(db, user_id=current_user.id, search=search, category_id=category_id, priority=priority, is_completed=is_completed)
    return tasks

@app.post("/api/tasks", response_model=schemas.Task)
def create_task(
    task: schemas.TaskCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """新規タスクを作成"""
    return crud.create_task(db=db, task=task, user_id=current_user.id)

@app.get("/api/tasks/{task_id}", response_model=schemas.Task)
def get_task(
    task_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """特定のタスクを取得"""
    db_task = crud.get_task(db, task_id=task_id, user_id=current_user.id)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.put("/api/tasks/{task_id}", response_model=schemas.Task)
def update_task(
    task_id: int, 
    task: schemas.TaskUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """タスクを更新"""
    db_task = crud.update_task(db, task_id=task_id, task=task, user_id=current_user.id)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.delete("/api/tasks/{task_id}")
def delete_task(
    task_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """タスクを削除"""
    success = crud.delete_task(db, task_id=task_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"message": "Task deleted successfully"}

# Category endpoints
@app.get("/api/categories", response_model=List[schemas.Category])
def get_categories(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """ユーザーのカテゴリを取得"""
    categories = crud.get_categories(db, user_id=current_user.id)
    return categories

@app.post("/api/categories", response_model=schemas.Category)
def create_category(
    category: schemas.CategoryCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """新規カテゴリを作成"""
    return crud.create_category(db=db, category=category, user_id=current_user.id)

@app.get("/api/categories/{category_id}", response_model=schemas.Category)
def get_category(
    category_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """特定のカテゴリを取得"""
    db_category = crud.get_category(db, category_id=category_id, user_id=current_user.id)
    if db_category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return db_category

@app.put("/api/categories/{category_id}", response_model=schemas.Category)
def update_category(
    category_id: int, 
    category: schemas.CategoryUpdate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """カテゴリを更新"""
    db_category = crud.update_category(db, category_id=category_id, category=category, user_id=current_user.id)
    if db_category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return db_category

@app.delete("/api/categories/{category_id}")
def delete_category(
    category_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """カテゴリを削除"""
    success = crud.delete_category(db, category_id=category_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")
    return {"message": "Category deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host=settings.host, 
        port=settings.port,
        reload=settings.debug
    )