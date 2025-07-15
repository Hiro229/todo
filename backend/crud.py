from sqlalchemy.orm import Session
from sqlalchemy import desc, or_
from typing import Optional
from passlib.context import CryptContext
from datetime import datetime
import models, schemas

# パスワードハッシュ化
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """パスワードを検証"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """パスワードをハッシュ化"""
    return pwd_context.hash(password)

# User CRUD operations
def get_user_by_email(db: Session, email: str):
    """メールアドレスでユーザーを取得"""
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_username(db: Session, username: str):
    """ユーザー名でユーザーを取得"""
    return db.query(models.User).filter(models.User.username == username).first()

def get_user_by_id(db: Session, user_id: int):
    """IDでユーザーを取得"""
    return db.query(models.User).filter(models.User.id == user_id).first()

def create_user(db: Session, user: schemas.UserCreate):
    """新規ユーザーを作成"""
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str):
    """ユーザー認証"""
    user = get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        return False
    return user

def update_user_last_login(db: Session, user_id: int):
    """最終ログイン時刻を更新"""
    db_user = get_user_by_id(db, user_id)
    if db_user:
        db_user.last_login = datetime.utcnow()
        db.commit()
        db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    """ユーザー情報を更新"""
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return None
    
    update_data = user_update.model_dump(exclude_unset=True)
    
    # パスワードがある場合はハッシュ化
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data.pop("password"))
    
    for key, value in update_data.items():
        setattr(db_user, key, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user

# Task CRUD operations
def get_tasks(db: Session, user_id: int, search: Optional[str] = None, category_id: Optional[int] = None, 
              priority: Optional[int] = None, is_completed: Optional[bool] = None):
    """ユーザーのタスクを条件付きで取得"""
    query = db.query(models.Task).filter(models.Task.user_id == user_id)
    
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

def get_task(db: Session, task_id: int, user_id: int):
    """ユーザーの特定のタスクを取得"""
    return db.query(models.Task).filter(
        models.Task.id == task_id, 
        models.Task.user_id == user_id
    ).first()

def create_task(db: Session, task: schemas.TaskCreate, user_id: int):
    """新規タスクを作成"""
    db_task = models.Task(
        title=task.title,
        description=task.description,
        priority=task.priority,
        due_date=task.due_date,
        category_id=task.category_id,
        user_id=user_id
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def update_task(db: Session, task_id: int, task: schemas.TaskUpdate, user_id: int):
    """タスクを更新"""
    db_task = db.query(models.Task).filter(
        models.Task.id == task_id,
        models.Task.user_id == user_id
    ).first()
    if db_task is None:
        return None
    
    update_data = task.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_task, key, value)
    
    db.commit()
    db.refresh(db_task)
    return db_task

def delete_task(db: Session, task_id: int, user_id: int):
    """タスクを削除"""
    db_task = db.query(models.Task).filter(
        models.Task.id == task_id,
        models.Task.user_id == user_id
    ).first()
    if db_task is None:
        return False
    
    db.delete(db_task)
    db.commit()
    return True

# Category CRUD operations
def get_categories(db: Session, user_id: int):
    """ユーザーのカテゴリを取得"""
    return db.query(models.Category).filter(
        models.Category.user_id == user_id
    ).order_by(models.Category.name).all()

def get_category(db: Session, category_id: int, user_id: int):
    """ユーザーの特定のカテゴリを取得"""
    return db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user_id
    ).first()

def create_category(db: Session, category: schemas.CategoryCreate, user_id: int):
    """新規カテゴリを作成"""
    db_category = models.Category(
        name=category.name, 
        color=category.color,
        user_id=user_id
    )
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def update_category(db: Session, category_id: int, category: schemas.CategoryUpdate, user_id: int):
    """カテゴリを更新"""
    db_category = db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user_id
    ).first()
    if db_category is None:
        return None
    
    update_data = category.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_category, key, value)
    
    db.commit()
    db.refresh(db_category)
    return db_category

def delete_category(db: Session, category_id: int, user_id: int):
    """カテゴリを削除"""
    db_category = db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user_id
    ).first()
    if db_category is None:
        return False
    
    # カテゴリに属するタスクのcategory_idをNullに設定
    db.query(models.Task).filter(
        models.Task.category_id == category_id,
        models.Task.user_id == user_id
    ).update({models.Task.category_id: None})
    
    db.delete(db_category)
    db.commit()
    return True