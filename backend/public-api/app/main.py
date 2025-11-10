"""
Antiplagiat Public API - Production Version
"""
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
import hashlib
import random
import uuid
from datetime import datetime
import re

app = FastAPI(
    title="Antiplagiat API",
    version="2.0.0",
    description="AI-powered plagiarism detection API",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://antiplagiat-frontend.onrender.com",
        "http://localhost:3000"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage (заменим на PostgreSQL позже)
checks_db = {}
sources_db = [
    {"id": 1, "title": "Wikipedia - Плагиат", "url": "https://ru.wikipedia.org/wiki/Плагиат", "domain": "wikipedia.org"},
    {"id": 2, "title": "Научная статья", "url": "https://cyberleninka.ru/article/n/plagiat", "domain": "cyberleninka.ru"},
    {"id": 3, "title": "Habr - Детекция плагиата", "url": "https://habr.com/ru/articles/plagiarism", "domain": "habr.com"},
]

# ============================================
# Models
# ============================================
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
    type: str  # "lexical" or "semantic"

class CheckResponse(BaseModel):
    task_id: str
    status: str
    estimated_time_seconds: int

class CheckResult(BaseModel):
    task_id: str
    status: str
    originality: Optional[float] = None
    total_words: Optional[int] = None
    total_chars: Optional[int] = None
    matches: Optional[List[Match]] = None
    sources: Optional[List[dict]] = None
    created_at: Optional[str] = None

# ============================================
# Базовый алгоритм детекции
# ============================================
def detect_plagiarism(text: str, mode: str = "fast") -> dict:
    """
    Упрощенный алгоритм детекции плагиата
    В production заменить на ML-модель
    """
    # Базовая статистика
    words = text.split()
    total_words = len(words)
    total_chars = len(text)
    
    # Поиск общих фраз (mock)
    common_phrases = [
        "искусственный интеллект",
        "машинное обучение",
        "нейронные сети",
        "глубокое обучение",
        "обработка естественного языка",
        "компьютерное зрение",
        "большие данные",
        "анализ данных"
    ]
    
    matches = []
    text_lower = text.lower()
    
    for phrase in common_phrases:
        if phrase in text_lower:
            start = text_lower.find(phrase)
            end = start + len(phrase)
            
            # Случайный источник
            source = random.choice(sources_db)
            
            matches.append({
                "start": start,
                "end": end,
                "text": text[start:end],
                "source_id": source["id"],
                "similarity": round(random.uniform(0.75, 0.95), 2),
                "type": "lexical" if mode == "fast" else random.choice(["lexical", "semantic"])
            })
    
    # Расчет уникальности
    if matches:
        matched_chars = sum(m["end"] - m["start"] for m in matches)
        originality = round(100 - (matched_chars / total_chars * 100), 2)
    else:
        originality = round(random.uniform(85, 98), 2)
    
    # Группировка источников
    source_stats = {}
    for match in matches:
        sid = match["source_id"]
        if sid not in source_stats:
            source_stats[sid] = {
                "source": next(s for s in sources_db if s["id"] == sid),
                "match_count": 0,
                "total_similarity": 0
            }
        source_stats[sid]["match_count"] += 1
        source_stats[sid]["total_similarity"] += match["similarity"]
    
    sources = [
        {
            **stat["source"],
            "match_count": stat["match_count"],
            "avg_similarity": round(stat["total_similarity"] / stat["match_count"], 2)
        }
        for stat in source_stats.values()
    ]
    
    return {
        "originality": originality,
        "total_words": total_words,
        "total_chars": total_chars,
        "matches": matches,
        "sources": sources
    }

# ============================================
# Endpoints
# ============================================
@app.get("/")
async def root():
    return {
        "service": "Antiplagiat API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs"
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "checks_in_memory": len(checks_db)
    }

@app.post("/api/v1/check", response_model=CheckResponse)
async def create_check(request: CheckRequest):
    """
    Создать проверку на плагиат
    """
    task_id = str(uuid.uuid4())
    
    # Запускаем проверку (в реальности это будет async task)
    result = detect_plagiarism(request.text, request.mode)
    
    # Сохраняем результат
    checks_db[task_id] = {
        "task_id": task_id,
        "status": "completed",
        "created_at": datetime.utcnow().isoformat(),
        **result
    }
    
    estimated_time = 5 if request.mode == "fast" else 15
    
    return CheckResponse(
        task_id=task_id,
        status="completed",
        estimated_time_seconds=estimated_time
    )

@app.get("/api/v1/check/{task_id}", response_model=CheckResult)
async def get_check_result(task_id: str):
    """
    Получить результат проверки
    """
    if task_id not in checks_db:
        raise HTTPException(status_code=404, detail="Check not found")
    
    return checks_db[task_id]

@app.get("/api/v1/sources")
async def get_sources():
    """
    Список доступных источников
    """
    return {
        "total": len(sources_db),
        "sources": sources_db
    }

@app.delete("/api/v1/check/{task_id}")
async def delete_check(task_id: str):
    """
    Удалить проверку (GDPR compliance)
    """
    if task_id in checks_db:
        del checks_db[task_id]
        return {"message": "Check deleted successfully"}
    
    raise HTTPException(status_code=404, detail="Check not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)