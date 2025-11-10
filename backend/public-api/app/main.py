"""
Antiplagiat API - Google Search Integration
"""
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
from sqlalchemy.orm import Session
import uuid
from datetime import datetime
import logging

from app.core.config import settings
from app.services.detector import detector
from app.models import CheckResult, get_db, init_db

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-powered plagiarism detection using Google Search",
    docs_url="/docs",
    redoc_url="/redoc",
    debug=settings.DEBUG
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS_LIST,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    init_db()
    logger.info("✓ Database initialized")

# Models
class CheckRequest(BaseModel):
    text: str = Field(..., min_length=100, max_length=500000)
    mode: str = Field(default="fast", pattern="^(fast|deep)$")
    lang: str = Field(default="ru", pattern="^(ru|en|kk)$")
    exclude_quotes: bool = True
    exclude_bibliography: bool = True

class Match(BaseModel):
    start: int
    end: int
    text: str
    source_id: int
    similarity: float
    type: str

class CheckResponse(BaseModel):
    task_id: str
    status: str
    estimated_time_seconds: int

class CheckResultResponse(BaseModel):
    task_id: str
    status: str
    originality: Optional[float] = None
    total_words: Optional[int] = None
    total_chars: Optional[int] = None
    matches: Optional[List[Match]] = None
    sources: Optional[List[dict]] = None
    created_at: Optional[str] = None
    ai_powered: bool = False
    note: Optional[str] = None

@app.get("/")
async def root():
    return {
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "google_search_enabled": bool(detector.google_api_key and detector.google_cx),
        "status": "running",
        "docs": "/docs"
    }

@app.get("/health")
async def health(db: Session = Depends(get_db)):
    try:
        db.execute("SELECT 1")
        db_status = "connected"
    except:
        db_status = "disconnected"
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "google_search_enabled": bool(detector.google_api_key and detector.google_cx),
        "database": db_status,
        "environment": settings.ENVIRONMENT
    }

@app.post("/api/v1/check", response_model=CheckResponse)
async def create_check(
    request: CheckRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Проверка текста на плагиат
    
    Fast режим: быстрая эвристика (mock)
    Deep режим: Google Search (реальная детекция)
    """
    task_id = str(uuid.uuid4())
    
    # Анализ через новый детектор
    result = detector.analyze(request.text, mode=request.mode)
    
    total_words = len(request.text.split())
    total_chars = len(request.text)
    
    # Сохраняем в БД
    db_result = CheckResult(
        task_id=task_id,
        status="completed",
        originality=result.get('originality', 0),
        total_words=total_words,
        total_chars=total_chars,
        matches=result.get('matches', []),
        sources=result.get('sources', []),
        ai_powered=result.get('google_used', False),
        created_at=datetime.utcnow()
    )
    db.add(db_result)
    db.commit()
    
    estimated_time = 15 if request.mode == "deep" else 3
    
    google_status = "✓" if result.get('google_used') else "✗"
    logger.info(f"{google_status} Check {task_id}: {result.get('originality')}%, mode={request.mode}, google={result.get('google_used', False)}, matches={len(result.get('matches', []))}")
    
    return CheckResponse(
        task_id=task_id,
        status="completed",
        estimated_time_seconds=estimated_time
    )

@app.get("/api/v1/check/{task_id}", response_model=CheckResultResponse)
async def get_check_result(task_id: str, db: Session = Depends(get_db)):
    """Получение результатов проверки"""
    result = db.query(CheckResult).filter(CheckResult.task_id == task_id).first()
    if not result:
        raise HTTPException(status_code=404, detail="Check not found")
    
    return CheckResultResponse(
        task_id=result.task_id,
        status=result.status,
        originality=result.originality,
        total_words=result.total_words,
        total_chars=result.total_chars,
        matches=result.matches,
        sources=result.sources,
        created_at=result.created_at.isoformat() if result.created_at else None,
        ai_powered=result.ai_powered,
        note="Deep режим использует Google Search для реальной детекции" if result.ai_powered else "Fast режим - для точной проверки используйте Deep"
    )

@app.delete("/api/v1/check/{task_id}")
async def delete_check(task_id: str, db: Session = Depends(get_db)):
    """Удаление проверки"""
    result = db.query(CheckResult).filter(CheckResult.task_id == task_id).first()
    if result:
        db.delete(result)
        db.commit()
        return {"message": "Check deleted"}
    raise HTTPException(status_code=404, detail="Check not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)