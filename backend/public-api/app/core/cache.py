"""Redis caching layer"""
import redis
import hashlib
import json
import os
import logging

logger = logging.getLogger(__name__)

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

try:
    redis_client = redis.from_url(REDIS_URL, decode_responses=True)
    redis_client.ping()
    logger.info("✓ Redis connected")
except Exception as e:
    logger.warning(f"⚠️ Redis unavailable: {e}")
    redis_client = None

def get_cache_key(prefix: str, data: str) -> str:
    hash_value = hashlib.sha256(data.encode()).hexdigest()
    return f"{prefix}:{hash_value}"

def get_cached(key: str):
    if not redis_client:
        return None
    try:
        cached = redis_client.get(key)
        if cached:
            logger.debug(f"Cache HIT: {key[:50]}")
            return json.loads(cached)
    except:
        pass
    return None

def set_cached(key: str, value: dict, ttl: int = 86400):
    if not redis_client:
        return False
    try:
        redis_client.setex(key, ttl, json.dumps(value))
        return True
    except:
        return False

def cache_google_search(query: str, results: list):
    key = get_cache_key("google", query)
    set_cached(key, results, ttl=86400 * 30)

def get_cached_google_search(query: str):
    key = get_cache_key("google", query)
    return get_cached(key)
