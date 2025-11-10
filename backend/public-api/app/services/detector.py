"""
Plagiarism Detection - Google Search Only
Deep режим: 100% Google Search (реальная детекция)
Fast режим: Простая mock проверка (быстро)
"""
import re
import os
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class GooglePlagiarismDetector:
    """
    Детектор плагиата на основе Google Search
    """
    
    def __init__(self):
        self.google_api_key = os.getenv("GOOGLE_SEARCH_API_KEY", "")
        self.google_cx = os.getenv("GOOGLE_SEARCH_CX", "")
        
        if self.google_api_key and self.google_cx:
            logger.info("✓ Google Search API настроен")
        else:
            logger.warning("⚠️  Google Search API не настроен (используйте Deep режим)")
    
    def analyze(self, text: str, mode: str = "fast") -> Dict:
        """
        Главный метод анализа
        
        Args:
            text: Текст для проверки
            mode: "fast" (быстро, mock) или "deep" (Google Search)
        """
        
        if mode == "deep":
            # Deep режим: ТОЛЬКО Google Search
            return self._google_search_analysis(text)
        else:
            # Fast режим: Простая mock проверка
            return self._fast_mock_analysis(text)
    
    def _fast_mock_analysis(self, text: str) -> Dict:
        """
        Fast режим: простая эвристика без Google
        Быстро, но неточно - для демо
        """
        words = text.split()
        total_words = len(words)
        total_chars = len(text)
        
        # Простая эвристика: если есть популярные фразы - подозрительно
        common_phrases = [
            "искусственный интеллект", "машинное обучение", "нейронные сети",
            "глубокое обучение", "обработка естественного языка",
            "neural network", "deep learning", "machine learning",
            "artificial intelligence"
        ]
        
        text_lower = text.lower()
        found_phrases = sum(1 for phrase in common_phrases if phrase in text_lower)
        
        # Чем больше популярных фраз - тем ниже "оригинальность"
        # Но это очень грубо!
        if found_phrases >= 3:
            originality = 75.0
        elif found_phrases >= 2:
            originality = 85.0
        else:
            originality = 92.0
        
        return {
            'originality': originality,
            'matches': [],
            'sources': [],
            'google_used': False,
            'mode': 'fast',
            'note': 'Fast mode - используйте Deep режим для точной проверки'
        }
    
    def _google_search_analysis(self, text: str) -> Dict:
        """
        Deep режим: ТОЛЬКО Google Search
        Реальная детекция плагиата
        """
        if not self.google_api_key or not self.google_cx:
            logger.error("Google Search API не настроен!")
            return {
                'originality': 0.0,
                'matches': [],
                'sources': [],
                'google_used': False,
                'error': 'Google Search API не настроен. Добавьте GOOGLE_SEARCH_API_KEY и GOOGLE_SEARCH_CX в переменные окружения.'
            }
        
        words = text.split()
        total_words = len(words)
        total_chars = len(text)
        
        # Разбиваем на предложения
        sentences = self._split_sentences(text)
        
        if not sentences:
            return {
                'originality': 100.0,
                'matches': [],
                'sources': [],
                'google_used': False,
                'error': 'Текст слишком короткий для анализа'
            }
        
        # Проверяем первые 5 предложений в Google
        matches = []
        sources_dict = {}
        
        sentences_to_check = sentences[:5]  # Максимум 5 предложений
        
        logger.info(f"Проверяем {len(sentences_to_check)} предложений через Google Search...")
        
        for i, sentence in enumerate(sentences_to_check):
            if len(sentence) < 50:  # Пропускаем короткие
                continue
            
            # Поиск в Google
            google_results = self._search_in_google(sentence)
            
            if google_results:
                # Нашли совпадение!
                for result in google_results:
                    matches.append({
                        'start': text.find(sentence),
                        'end': text.find(sentence) + len(sentence),
                        'text': sentence,
                        'source_id': result['source_id'],
                        'similarity': result['similarity'],
                        'type': 'google_exact'
                    })
                    
                    # Добавляем источник
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
        
        # Рассчитываем оригинальность
        if matches:
            # Убираем дубликаты по позиции
            unique_matches = {}
            for match in matches:
                key = (match['start'], match['end'])
                if key not in unique_matches or unique_matches[key]['similarity'] < match['similarity']:
                    unique_matches[key] = match
            
            matches = list(unique_matches.values())
            
            # Считаем сколько символов скопировано
            matched_chars = sum(m['end'] - m['start'] for m in matches)
            originality = max(0, round(100 - (matched_chars / total_chars * 100), 2))
        else:
            # Ничего не найдено в Google
            originality = 95.0
        
        sources = list(sources_dict.values())
        
        logger.info(f"✓ Google Search завершен: {originality}% оригинальности, {len(matches)} совпадений, {len(sources)} источников")
        
        return {
            'originality': originality,
            'matches': matches,
            'sources': sorted(sources, key=lambda x: x['match_count'], reverse=True),
            'google_used': True,
            'mode': 'deep'
        }
    
    def _split_sentences(self, text: str) -> List[str]:
        """Разбивка текста на предложения"""
        sentences = re.split(r'[.!?]+', text)
        return [s.strip() for s in sentences if len(s.strip()) > 30]
    
    def _search_in_google(self, query: str) -> List[Dict]:
        """
        Поиск в Google Custom Search API
        
        Args:
            query: Текст для поиска
            
        Returns:
            Список найденных источников
        """
        try:
            import httpx
            
            # Google Custom Search API
            url = "https://www.googleapis.com/customsearch/v1"
            
            # Берем первые 150 символов для поиска
            search_query = query[:150]
            
            params = {
                'key': self.google_api_key,
                'cx': self.google_cx,
                'q': f'"{search_query}"',  # Точное совпадение
                'num': 5  # Максимум 5 результатов
            }
            
            logger.debug(f"Google Search запрос: {search_query[:50]}...")
            
            response = httpx.get(url, params=params, timeout=15)
            
            if response.status_code != 200:
                logger.error(f"Google Search error: HTTP {response.status_code}")
                logger.error(f"Response: {response.text[:200]}")
                return []
            
            data = response.json()
            
            if 'items' not in data:
                logger.debug("Google Search: совпадений не найдено")
                return []
            
            results = []
            for item in data['items']:
                source_id = hash(item['link']) % 100000
                
                results.append({
                    'source_id': source_id,
                    'title': item.get('title', 'Untitled')[:200],
                    'url': item.get('link', ''),
                    'domain': item.get('displayLink', 'unknown'),
                    'similarity': 0.95  # Точное совпадение в Google
                })
            
            logger.info(f"✓ Google нашел {len(results)} источников")
            return results
            
        except Exception as e:
            logger.error(f"Google Search error: {e}")
            return []

# Singleton
detector = GooglePlagiarismDetector()