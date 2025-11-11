"""Configuration management"""
from pydantic_settings import BaseSettings
from typing import List
import os
from functools import lru_cache

class Settings(BaseSettings):
    """Application settings"""
    
    # Application
    APP_NAME: str = "Antiplagiat API"
    APP_VERSION: str = "2.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    PORT: int = 8001
    
    # Security
    JWT_SECRET: str = "change-me-in-production"
    API_KEY_SECRET: str = "change-me-in-production"
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000"
    
    @property
    def ALLOWED_ORIGINS_LIST(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    # Database
    DATABASE_URL: str = "sqlite:///./antiplagiat.db"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Google Search API
    GOOGLE_SEARCH_API_KEY: str = ""
    GOOGLE_SEARCH_CX: str = ""
    
    # AI Configuration
    OPENROUTER_API_KEY: str = ""
    AI_MODEL: str = "google/gemini-2.0-flash-exp:free"
    AI_BASE_URL: str = "https://openrouter.ai/api/v1/chat/completions"
    AI_TIMEOUT: int = 30
    AI_MAX_RETRIES: int = 3
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_DAY: int = 1000
    
    # File Upload
    MAX_FILE_SIZE_MB: int = 10
    ALLOWED_FILE_TYPES: str = "txt,pdf,docx,rtf"
    
    @property
    def ALLOWED_FILE_TYPES_LIST(self) -> List[str]:
        return [ft.strip() for ft in self.ALLOWED_FILE_TYPES.split(",")]
    
    @property
    def MAX_FILE_SIZE_BYTES(self) -> int:
        return self.MAX_FILE_SIZE_MB * 1024 * 1024
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"  # Игнорировать дополнительные поля

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
