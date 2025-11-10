'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { apiClient, CheckResult } from '@/lib/api'

export default function ReportPage() {
  const params = useParams()
  const router = useRouter()
  const [result, setResult] = useState<CheckResult | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchResult = async () => {
      try {
        const data = await apiClient.getCheckResult(params.id as string)
        setResult(data)
      } catch (err: any) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }
    fetchResult()
  }, [params.id])

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>⏳</div>
          <div style={{ fontSize: '1.5rem', color: '#718096' }}>Загрузка результатов...</div>
        </div>
      </div>
    )
  }

  if (error || !result) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>❌</div>
          <div style={{ fontSize: '1.5rem', color: '#e53e3e', marginBottom: '1rem' }}>
            {error || 'Отчет не найден'}
          </div>
          <button
            onClick={() => router.push('/')}
            style={{
              padding: '0.75rem 1.5rem',
              background: '#3182ce',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '1rem'
            }}
          >
            Вернуться на главную
          </button>
        </div>
      </div>
    )
  }

  const originality = result.originality || 0
  const isGood = originality >= 80
  const isWarning = originality >= 60 && originality < 80

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(to bottom, #ffffff, #f7fafc)' }}>
      <header style={{
        background: 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(10px)',
        borderBottom: '1px solid #e2e8f0',
        padding: '1rem 2rem'
      }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button onClick={() => router.push('/')} style={{
            padding: '0.5rem 1rem', background: 'transparent', border: '2px solid #e2e8f0',
            borderRadius: '8px', cursor: 'pointer', fontSize: '1rem'
          }}>← Назад</button>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ fontSize: '1.5rem' }}>🔍</span>
            <span style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>Antiplagiat</span>
          </div>
        </div>
      </header>      <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '3rem 2rem' }}>
        <div style={{
          background: 'white', borderRadius: '16px', padding: '3rem',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.1)', marginBottom: '2rem'
        }}>
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <div style={{
              fontSize: '6rem', fontWeight: '800',
              color: isGood ? '#38a169' : isWarning ? '#d69e2e' : '#e53e3e',
              marginBottom: '1rem'
            }}>{originality.toFixed(1)}%</div>
            <div style={{ fontSize: '1.5rem', color: '#718096', marginBottom: '1rem' }}>
              {isGood && '✅ Отличная оригинальность'}
              {isWarning && '⚠️ Средняя оригинальность'}
              {!isGood && !isWarning && '❌ Низкая оригинальность'}
            </div>
            {result.ai_powered && (
              <div style={{
                display: 'inline-block', padding: '0.5rem 1rem',
                background: '#805ad5', color: 'white', borderRadius: '8px', fontSize: '0.875rem'
              }}>🤖 AI-анализ с Google Gemini 2.0</div>
            )}
          </div>

          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '1.5rem', marginBottom: '3rem'
          }}>
            <div style={{ padding: '1.5rem', background: '#f7fafc', borderRadius: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>📝</div>
              <div style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '0.25rem' }}>
                {result.total_words?.toLocaleString()}
              </div>
              <div style={{ color: '#718096', fontSize: '0.875rem' }}>Слов</div>
            </div>
            <div style={{ padding: '1.5rem', background: '#f7fafc', borderRadius: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🔤</div>
              <div style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '0.25rem' }}>
                {result.total_chars?.toLocaleString()}
              </div>
              <div style={{ color: '#718096', fontSize: '0.875rem' }}>Символов</div>
            </div>
            <div style={{ padding: '1.5rem', background: '#f7fafc', borderRadius: '12px', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🎯</div>
              <div style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '0.25rem' }}>
                {result.matches?.length || 0}
              </div>
              <div style={{ color: '#718096', fontSize: '0.875rem' }}>Совпадений</div>
            </div>
          </div>

          {result.matches && result.matches.length > 0 && (
            <div>
              <h2 style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '1.5rem' }}>
                Найденные совпадения
              </h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {result.matches.map((match, i) => (
                  <div key={i} style={{
                    padding: '1.5rem', background: '#fef5e7', border: '2px solid #f6ad55', borderRadius: '12px'
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
                      <span style={{ fontWeight: '600', color: '#744210' }}>Совпадение #{i + 1}</span>
                      <span style={{
                        padding: '0.25rem 0.75rem', background: '#f6ad55', color: 'white',
                        borderRadius: '6px', fontSize: '0.875rem', fontWeight: '600'
                      }}>{(match.similarity * 100).toFixed(0)}% схожесть</span>
                    </div>
                    <div style={{
                      padding: '1rem', background: 'white', borderRadius: '8px',
                      fontStyle: 'italic', color: '#2d3748'
                    }}>"{match.text}"</div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {result.sources && result.sources.length > 0 && (
            <div style={{ marginTop: '3rem' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '1.5rem' }}>
                Источники ({result.sources.length})
              </h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {result.sources.map((source, i) => (
                  <div key={i} style={{
                    padding: '1.5rem', background: '#f7fafc', borderRadius: '12px',
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center'
                  }}>
                    <div>
                      <div style={{ fontWeight: '600', marginBottom: '0.25rem' }}>{source.title}</div>
                      <a href={source.url} target="_blank" rel="noopener noreferrer"
                        style={{ color: '#3182ce', fontSize: '0.875rem', textDecoration: 'none' }}>
                        {source.domain} ↗
                      </a>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#3182ce' }}>
                        {source.match_count}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: '#718096' }}>совпадений</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
          <button onClick={() => router.push('/')} style={{
            padding: '1rem 2rem', background: '#3182ce', color: 'white',
            border: 'none', borderRadius: '8px', fontSize: '1rem',
            fontWeight: '600', cursor: 'pointer'
          }}>Проверить другой текст</button>
          <button onClick={() => window.print()} style={{
            padding: '1rem 2rem', background: 'white', color: '#3182ce',
            border: '2px solid #3182ce', borderRadius: '8px', fontSize: '1rem',
            fontWeight: '600', cursor: 'pointer'
          }}>📄 Распечатать отчет</button>
        </div>
      </div>
    </div>
  )
}