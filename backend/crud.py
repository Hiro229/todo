from sqlalchemy.orm import Session
from sqlalchemy import desc, or_
from typing import Optional
import models, schemas

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