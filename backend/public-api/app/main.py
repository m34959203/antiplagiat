from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from langdetect import detect, lang_detect_exception
import logging

from app.core.config import settings
from app.services import detector
from app.models import CheckResult, CheckRequest, create_db_and_tables, get_db

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Antiplagiat API",
    description="API для проверки текстов на уникальность.",
    version="2.0.0"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(','),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

@app.get("/", tags=["General"])
def read_root():
    return {"service": "Antiplagiat API", "version": "2.0.0", "status": "ok"}

@app.get("/health", tags=["General"])
def health_check():
    # Простая проверка, что API работает
    return {"status": "ok"}

@app.post("/api/v1/check", response_model=CheckResult, tags=["Plagiarism Check"])
async def create_check(request: CheckRequest, db: Session = Depends(get_db)):
    """
    Создает новую проверку текста.
    - **text**: Текст для проверки (минимум 100 символов).
    """
    text = request.text
    if not text or len(text) < 100:
        raise HTTPException(status_code=400, detail="Text must be at least 100 characters long.")

    # Автоматическое определение языка
    try:
        lang = detect(text)
    except lang_detect_exception.LangDetectException:
        lang = "en" # Fallback
        logger.warning("Could not detect language, falling back to 'en'")
        
    logger.info(f"Detected language: {lang}")

    # Теперь проверка всегда в режиме "deep"
    try:
        result_data = await detector.analyze(text, "deep", lang, db)
        return result_data
    except Exception as e:
        logger.error(f"Error during plagiarism check: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal error occurred during the check.")

@app.get("/api/v1/check/{task_id}", response_model=CheckResult, tags=["Plagiarism Check"])
def get_check_result(task_id: str, db: Session = Depends(get_db)):
    """
    Получает результат проверки по ее ID.
    """
    db_result = db.query(CheckResult).filter(CheckResult.task_id == task_id).first()
    if db_result is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_result
