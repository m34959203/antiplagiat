"""Database Models - Render Compatible"""
from sqlalchemy import Column, String, Float, Integer, DateTime, JSON, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

Base = declarative_base()

class CheckResult(Base):
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

# Database URL - поддержка Render
DATABASE_URL = os.getenv("DATABASE_URL")

# Если DATABASE_URL пустая или None - используем SQLite
if not DATABASE_URL or DATABASE_URL.strip() == "":
    DATABASE_URL = "sqlite:///./antiplagiat.db"
    print("📊 Database: SQLite (fallback)")
else:
    # Render использует postgres://, но SQLAlchemy требует postgresql://
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
        print("📊 Database: PostgreSQL (Render)")
    else:
        print(f"📊 Database: {'SQLite' if 'sqlite' in DATABASE_URL else 'PostgreSQL'}")

try:
    if "sqlite" in DATABASE_URL:
        engine = create_engine(
            DATABASE_URL,
            connect_args={"check_same_thread": False},
            echo=False
        )
    else:
        engine = create_engine(
            DATABASE_URL,
            pool_pre_ping=True,
            pool_size=10,
            max_overflow=20,
            echo=False
        )
    print("✓ Database engine created")
except Exception as e:
    print(f"❌ Database error: {e}")
    # Fallback to SQLite
    print("⚠️  Falling back to SQLite")
    DATABASE_URL = "sqlite:///./antiplagiat.db"
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        echo=False
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    try:
        Base.metadata.create_all(bind=engine)
        print("✓ Database tables created")
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        raise
