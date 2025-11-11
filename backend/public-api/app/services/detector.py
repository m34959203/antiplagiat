# -*- coding: utf-8 -*-
"""Plagiarism Detection - Google Search Integration"""
import re
from typing import List, Dict
import logging
from urllib.parse import quote

logger = logging.getLogger(__name__)

class GooglePlagiarismDetector:
    
    def __init__(self):
        from app.core.config import settings
        
        self.google_api_key = settings.GOOGLE_SEARCH_API_KEY
        self.google_cx = settings.GOOGLE_SEARCH_CX
        
        logger.info("=" * 60)
        logger.info("DETECTOR INIT")
        logger.info(f"API Key: {bool(self.google_api_key)}")
        logger.info(f"CX: {self.google_cx}")
        logger.info("=" * 60)
    
    def analyze(self, text: str, mode: str = "fast") -> Dict:
        logger.info(f"analyze() mode={mode}, len={len(text)}")
        
        if mode == "deep" and self.google_api_key and self.google_cx:
            logger.info("Using Google Search")
            return self._google_search_analysis(text)
        else:
            return self._fast_mock_analysis(text)
    
    def _fast_mock_analysis(self, text: str) -> Dict:
        originality = 92.0
        return {
            'originality': originality,
            'matches': [],
            'sources': [],
            'google_used': False,
            'mode': 'fast'
        }
    
    def _google_search_analysis(self, text: str) -> Dict:
        from app.core.cache import get_cached_google_search, cache_google_search
        
        logger.info("Google Search analysis...")
        
        total_chars = len(text)
        sentences = self._split_sentences(text)
        
        logger.info(f"Sentences: {len(sentences)}")
        
        if not sentences:
            return {
                'originality': 100.0,
                'matches': [],
                'sources': [],
                'google_used': False
            }
        
        matches = []
        sources_dict = {}
        
        for i, sentence in enumerate(sentences[:5], 1):
            if len(sentence) < 50:
                continue
            
            # Логируем первые 50 символов
            preview = sentence[:50] if len(sentence) > 50 else sentence
            logger.info(f"Sentence {i}: checking...")
            
            results = self._search_in_google(sentence)
            
            logger.info(f"Found {len(results)} results")
            
            if results:
                for result in results:
                    matches.append({
                        'start': text.find(sentence),
                        'end': text.find(sentence) + len(sentence),
                        'text': sentence,
                        'source_id': result['source_id'],
                        'similarity': result['similarity'],
                        'type': 'google_exact'
                    })
                    
                    source_id = result['source_id']
                    if source_id not in sources_dict:
                        sources_dict[source_id] = {
                            'id': source_id,
                            'title': result['title'],
                            'url': result['url'],
                            'domain': result['domain'],
                            'match_count': 0
                        }
                    sources_dict[source_id]['match_count'] += 1
        
        if matches:
            unique = {}
            for m in matches:
                key = (m['start'], m['end'])
                if key not in unique or unique[key]['similarity'] < m['similarity']:
                    unique[key] = m
            
            matches = list(unique.values())
            weighted = sum((m['end'] - m['start']) * m['similarity'] for m in matches)
            originality = max(0, min(100, round(100 - (weighted / total_chars * 100), 2)))
            
            logger.info(f"Matches: {len(matches)}, originality={originality}%")
        else:
            originality = 95.0
            logger.info("No matches, originality=95%")
        
        sources = list(sources_dict.values())
        
        return {
            'originality': originality,
            'matches': matches,
            'sources': sorted(sources, key=lambda x: x['match_count'], reverse=True),
            'google_used': True,
            'mode': 'deep'
        }
    
    def _split_sentences(self, text: str) -> List[str]:
        parts = text.replace('?', '.').replace('!', '.').split('.')
        sentences = [s.strip() for s in parts if len(s.strip()) > 40]
        
        if not sentences and len(text.strip()) > 40:
            sentences = [text.strip()]
        
        logger.info(f"Split into {len(sentences)} sentences")
        
        return sentences
    
    def _search_in_google(self, query: str) -> List[Dict]:
        from app.core.cache import get_cached_google_search, cache_google_search
        
        cached = get_cached_google_search(query)
        if cached:
            logger.info("Cache HIT")
            return cached
        
        try:
            import httpx
            
            url = "https://www.googleapis.com/customsearch/v1"
            
            # Обрезаем запрос до 150 символов
            search_query = query[:150]
            
            params = {
                'key': self.google_api_key,
                'cx': self.google_cx,
                'q': search_query,
                'num': 5
            }
            
            logger.info("Google API call...")
            
            # httpx автоматически кодирует UTF-8
            response = httpx.get(url, params=params, timeout=15)
            
            logger.info(f"HTTP {response.status_code}")
            
            if response.status_code != 200:
                logger.error(f"Error: {response.text[:200]}")
                return []
            
            data = response.json()
            
            if 'items' not in data:
                if 'error' in data:
                    logger.error(f"Google API error: {data['error']}")
                else:
                    logger.info("No results found")
                return []
            
            results = [
                {
                    'source_id': hash(item['link']) % 100000,
                    'title': item.get('title', 'Untitled')[:200],
                    'url': item.get('link', ''),
                    'domain': item.get('displayLink', 'unknown'),
                    'similarity': 0.95
                }
                for item in data['items']
            ]
            
            cache_google_search(query, results)
            
            logger.info(f"Found {len(results)} sources")
            
            return results
            
        except Exception as e:
            logger.error(f"Exception: {e}")
            return []

detector = GooglePlagiarismDetector()