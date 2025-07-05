from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
import models, schemas, crud, database
from database import SessionLocal, engine
from auth import verify_api_key, optional_api_key_auth

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="TODO App API", version="2.0.0")

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# データベース依存関数
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "TODO App API v2.0 - Phase 2 Features"}

# Task endpoints  
@app.get("/api/tasks", response_model=List[schemas.Task])
def get_tasks(
    search: Optional[str] = Query(None, description="検索キーワード"),
    category_id: Optional[int] = Query(None, description="カテゴリID"),
    priority: Optional[int] = Query(None, ge=1, le=3, description="優先度 (1=High, 2=Medium, 3=Low)"),
    is_completed: Optional[bool] = Query(None, description="完了状態"),
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """全タスクを条件付きで取得"""
    tasks = crud.get_tasks(db, search=search, category_id=category_id, priority=priority, is_completed=is_completed)
    return tasks

@app.post("/api/tasks", response_model=schemas.Task)
def create_task(
    task: schemas.TaskCreate,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """新規タスクを作成"""
    return crud.create_task(db=db, task=task)

@app.get("/api/tasks/{task_id}", response_model=schemas.Task)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """特定のタスクを取得"""
    db_task = crud.get_task(db, task_id=task_id)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.put("/api/tasks/{task_id}", response_model=schemas.Task)
def update_task(
    task_id: int,
    task: schemas.TaskUpdate,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """タスクを更新"""
    db_task = crud.update_task(db, task_id=task_id, task=task)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.delete("/api/tasks/{task_id}")
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """タスクを削除"""
    success = crud.delete_task(db, task_id=task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"message": "Task deleted successfully"}

# Category endpoints
@app.get("/api/categories", response_model=List[schemas.Category])
def get_categories(
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """全カテゴリを取得"""
    categories = crud.get_categories(db)
    return categories

@app.post("/api/categories", response_model=schemas.Category)
def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """新規カテゴリを作成"""
    return crud.create_category(db=db, category=category)

@app.get("/api/categories/{category_id}", response_model=schemas.Category)
def get_category(
    category_id: int,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """特定のカテゴリを取得"""
    db_category = crud.get_category(db, category_id=category_id)
    if db_category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return db_category

@app.put("/api/categories/{category_id}", response_model=schemas.Category)
def update_category(
    category_id: int,
    category: schemas.CategoryUpdate,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """カテゴリを更新"""
    db_category = crud.update_category(db, category_id=category_id, category=category)
    if db_category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return db_category

@app.delete("/api/categories/{category_id}")
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    _: Optional[models.ApiKey] = Depends(optional_api_key_auth)
):
    """カテゴリを削除"""
    success = crud.delete_category(db, category_id=category_id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")
    return {"message": "Category deleted successfully"}

# API Key endpoints
@app.post("/api/auth/keys", response_model=schemas.ApiKeyResponse)
def create_api_key(
    api_key_create: schemas.ApiKeyCreate,
    db: Session = Depends(get_db)
):
    """新しいAPIキーを作成"""
    db_api_key, plain_key = crud.create_api_key(db=db, api_key_create=api_key_create)
    return schemas.ApiKeyResponse(
        id=db_api_key.id,
        name=db_api_key.name,
        key=plain_key,
        is_active=db_api_key.is_active,
        created_at=db_api_key.created_at
    )

@app.get("/api/auth/keys", response_model=List[schemas.ApiKey])
def get_api_keys(
    db: Session = Depends(get_db),
    _: models.ApiKey = Depends(verify_api_key)
):
    """全APIキーを取得（認証必要）"""
    return crud.get_api_keys(db)

@app.delete("/api/auth/keys/{key_id}")
def delete_api_key(
    key_id: int,
    db: Session = Depends(get_db),
    _: models.ApiKey = Depends(verify_api_key)
):
    """あAPIキーを削除（認証必要）"""
    success = crud.delete_api_key(db, api_key_id=key_id)
    if not success:
        raise HTTPException(status_code=404, detail="API key not found")
    return {"message": "API key deleted successfully"}

@app.patch("/api/auth/keys/{key_id}/toggle")
def toggle_api_key(
    key_id: int,
    db: Session = Depends(get_db),
    _: models.ApiKey = Depends(verify_api_key)
):
    """あAPIキーの有効/無効を切り替え（認証必要）"""
    db_api_key = crud.toggle_api_key_status(db, api_key_id=key_id)
    if db_api_key is None:
        raise HTTPException(status_code=404, detail="API key not found")
    return {"message": f"API key {'activated' if db_api_key.is_active else 'deactivated'} successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)