"""Database Models (Render-safe: fallback to SQLite if DATABASE_URL empty)"""
import logging
logger = logging.getLogger(__name__)

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

def _pick_database_url() -> str:
    # Render может прокидывать разные переменные
    for key in ("DATABASE_URL", "DATABASE_INTERNAL_URL", "POSTGRES_URL", "POSTGRESQL_URL"):
        val = (os.getenv(key) or "").strip()
        if val:
            return val
    return ""

def _normalize(url: str) -> str:
    if url.startswith("postgres://"):
        return "postgresql+psycopg2://" + url[len("postgres://"):]
    if url.startswith("postgresql://"):
        return "postgresql+psycopg2://" + url[len("postgresql://"):]
    return url

DATABASE_URL = _pick_database_url()

# Fallback на SQLite даже в production, чтобы сервис поднялся
if not DATABASE_URL:
    logger.info("⚠️ DATABASE_URL is empty. Fallback to SQLite (ephemeral on Render).")
    DATABASE_URL = "sqlite:///./antiplagiat.db"

DATABASE_URL = _normalize(DATABASE_URL)

logger.info(f"📊 Database: {'SQLite' if DATABASE_URL.startswith('sqlite') else 'PostgreSQL'}")
try:
    if DATABASE_URL.startswith("sqlite"):
        engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False}, echo=False)
    else:
        engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_size=10, max_overflow=20, echo=False)
    logger.info("✓ Database engine created")
except Exception as e:
    logger.info(f"❌ Database error: {e}")
    raise

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
        logger.info("✓ Database tables created")
    except Exception as e:
        logger.info(f"❌ Error: {e}")
        raise

