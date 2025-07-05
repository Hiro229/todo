from sqlalchemy.orm import Session
from sqlalchemy import desc, or_
from typing import Optional
import models, schemas
import hashlib
import secrets

# Task CRUD operations
def get_tasks(db: Session, search: Optional[str] = None, category_id: Optional[int] = None, 
              priority: Optional[int] = None, is_completed: Optional[bool] = None):
    """全タスクを条件付きで取得"""
    query = db.query(models.Task)
    
    if search:
        query = query.filter(or_(
            models.Task.title.ilike(f"%{search}%"),
            models.Task.description.ilike(f"%{search}%")
        ))
    
    if category_id is not None:
        query = query.filter(models.Task.category_id == category_id)
    
    if priority is not None:
        query = query.filter(models.Task.priority == priority)
    
    if is_completed is not None:
        query = query.filter(models.Task.is_completed == is_completed)
    
    return query.order_by(desc(models.Task.created_at)).all()

def get_task(db: Session, task_id: int):
    """特定のタスクを取得"""
    return db.query(models.Task).filter(models.Task.id == task_id).first()

def create_task(db: Session, task: schemas.TaskCreate):
    """新規タスクを作成"""
    db_task = models.Task(
        title=task.title,
        description=task.description,
        priority=task.priority,
        due_date=task.due_date,
        category_id=task.category_id
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def update_task(db: Session, task_id: int, task: schemas.TaskUpdate):
    """タスクを更新"""
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task is None:
        return None
    
    update_data = task.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_task, key, value)
    
    db.commit()
    db.refresh(db_task)
    return db_task

def delete_task(db: Session, task_id: int):
    """タスクを削除"""
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task is None:
        return False
    
    db.delete(db_task)
    db.commit()
    return True

# Category CRUD operations
def get_categories(db: Session):
    """全カテゴリを取得"""
    return db.query(models.Category).order_by(models.Category.name).all()

def get_category(db: Session, category_id: int):
    """特定のカテゴリを取得"""
    return db.query(models.Category).filter(models.Category.id == category_id).first()

def create_category(db: Session, category: schemas.CategoryCreate):
    """新規カテゴリを作成"""
    db_category = models.Category(name=category.name, color=category.color)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def update_category(db: Session, category_id: int, category: schemas.CategoryUpdate):
    """カテゴリを更新"""
    db_category = db.query(models.Category).filter(models.Category.id == category_id).first()
    if db_category is None:
        return None
    
    update_data = category.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_category, key, value)
    
    db.commit()
    db.refresh(db_category)
    return db_category

def delete_category(db: Session, category_id: int):
    """カテゴリを削除"""
    db_category = db.query(models.Category).filter(models.Category.id == category_id).first()
    if db_category is None:
        return False
    
    # カテゴリに属するタスクのcategory_idをNullに設定
    db.query(models.Task).filter(models.Task.category_id == category_id).update(
        {models.Task.category_id: None}
    )
    
    db.delete(db_category)
    db.commit()
    return True

# API Key CRUD operations
def generate_api_key() -> str:
    """新しいAPIキーを生成"""
    return secrets.token_urlsafe(32)

def hash_api_key(api_key: str) -> str:
    """あAPIキーのハッシュを生成"""
    return hashlib.sha256(api_key.encode()).hexdigest()

def create_api_key(db: Session, api_key_create: schemas.ApiKeyCreate) -> tuple[models.ApiKey, str]:
    """新しいAPIキーを作成"""
    api_key = generate_api_key()
    key_hash = hash_api_key(api_key)
    
    db_api_key = models.ApiKey(
        key_hash=key_hash,
        name=api_key_create.name
    )
    db.add(db_api_key)
    db.commit()
    db.refresh(db_api_key)
    
    return db_api_key, api_key

def get_api_keys(db: Session):
    """全APIキーを取得"""
    return db.query(models.ApiKey).order_by(desc(models.ApiKey.created_at)).all()

def get_api_key_by_hash(db: Session, key_hash: str):
    """ハッシュでAPIキーを取得"""
    return db.query(models.ApiKey).filter(
        models.ApiKey.key_hash == key_hash,
        models.ApiKey.is_active == True
    ).first()

def verify_api_key(db: Session, api_key: str) -> Optional[models.ApiKey]:
    """あAPIキーを検証"""
    key_hash = hash_api_key(api_key)
    return get_api_key_by_hash(db, key_hash)

def delete_api_key(db: Session, api_key_id: int):
    """あAPIキーを削除"""
    db_api_key = db.query(models.ApiKey).filter(models.ApiKey.id == api_key_id).first()
    if db_api_key is None:
        return False
    
    db.delete(db_api_key)
    db.commit()
    return True

def toggle_api_key_status(db: Session, api_key_id: int):
    """あAPIキーの有効/無効を切り替え"""
    db_api_key = db.query(models.ApiKey).filter(models.ApiKey.id == api_key_id).first()
    if db_api_key is None:
        return None
    
    # 現在の状態を取得して反転
    new_status = not bool(db_api_key.is_active)
    db.query(models.ApiKey).filter(models.ApiKey.id == api_key_id).update(
        {"is_active": new_status}
    )
    db.commit()
    db.refresh(db_api_key)
    return db_api_key