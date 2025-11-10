"""
Database Models
"""
from sqlalchemy import Column, String, Float, Integer, Text, DateTime, JSON, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from app.core.config import settings

Base = declarative_base()

class CheckResult(Base):
    """Результат проверки на плагиат"""
    __tablename__ = "check_results"
    
    task_id = Column(String, primary_key=True, index=True)
    status = Column(String, default="pending")
    originality = Column(Float, nullable=True)
    total_words = Column(Integer, nullable=True)
    total_chars = Column(Integer, nullable=True)
    matches = Column(JSON, nullable=True)
    sources = Column(JSON, nullable=True)
    ai_powered = Column(String, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    user_id = Column(String, nullable=True, index=True)

# Database connection
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    echo=settings.DEBUG
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Dependency для FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Инициализация БД"""
    Base.metadata.create_all(bind=engine)
    print("✓ Database tables created")