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
          <div style={{
            width: '64px',
            height: '64px',
            border: '4px solid #e2e8f0',
            borderTopColor: '#3182ce',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 1rem'
          }} />
          <p style={{ color: '#718096' }}>Загрузка результатов...</p>
        </div>
      </div>
    )
  }

  if (error || !result) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>❌</div>
          <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>Ошибка</h1>
          <p style={{ color: '#718096', marginBottom: '2rem' }}>{error || 'Результат не найден'}</p>
          <button
            onClick={() => router.push('/')}
            style={{
              padding: '0.75rem 1.5rem',
              background: '#3182ce',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer'
            }}
          >
            На главную
          </button>
        </div>
      </div>
    )
  }

  const getOriginalityColor = (originality: number) => {
    if (originality >= 90) return '#38a169'
    if (originality >= 70) return '#d69e2e'
    return '#e53e3e'
  }

  return (
    <div style={{ minHeight: '100vh', background: '#f7fafc' }}>
      {/* Header */}
      <header style={{
        background: 'white',
        borderBottom: '1px solid #e2e8f0',
        padding: '1rem 2rem'
      }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button
            onClick={() => router.push('/')}
            style={{
              background: 'transparent',
              border: 'none',
              fontSize: '1.5rem',
              cursor: 'pointer'
            }}
          >
            ←
          </button>
          <div>
            <div style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>🔍 Antiplagiat</div>
            <div style={{ fontSize: '0.875rem', color: '#718096' }}>Результат проверки</div>
          </div>
        </div>
      </header>

      {/* Results */}
      <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
        {/* Originality Score */}
        <div style={{
          background: 'white',
          borderRadius: '16px',
          padding: '2rem',
          marginBottom: '2rem',
          boxShadow: '0 4px 12px rgba(0,0,0,0.05)',
          textAlign: 'center'
        }}>
          <div style={{
            fontSize: '5rem',
            fontWeight: '800',
            color: getOriginalityColor(result.originality || 0),
            marginBottom: '0.5rem'
          }}>
            {result.originality?.toFixed(1)}%
          </div>
          <div style={{ fontSize: '1.5rem', color: '#718096', marginBottom: '1rem' }}>
            Уникальность текста
          </div>
          <div style={{
            display: 'inline-flex',
            gap: '2rem',
            padding: '1rem 2rem',
            background: '#f7fafc',
            borderRadius: '8px'
          }}>
            <div>
              <div style={{ fontWeight: 'bold' }}>{result.total_words}</div>
              <div style={{ fontSize: '0.875rem', color: '#718096' }}>слов</div>
            </div>
            <div>
              <div style={{ fontWeight: 'bold' }}>{result.total_chars}</div>
              <div style={{ fontSize: '0.875rem', color: '#718096' }}>символов</div>
            </div>
            <div>
              <div style={{ fontWeight: 'bold' }}>{result.matches?.length || 0}</div>
              <div style={{ fontSize: '0.875rem', color: '#718096' }}>совпадений</div>
            </div>
          </div>
        </div>

        {/* Sources */}
        {result.sources && result.sources.length > 0 && (
          <div style={{
            background: 'white',
            borderRadius: '16px',
            padding: '2rem',
            marginBottom: '2rem',
            boxShadow: '0 4px 12px rgba(0,0,0,0.05)'
          }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>
              📚 Найденные источники
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {result.sources.map((source: any, i: number) => (
                <div key={i} style={{
                  padding: '1rem',
                  border: '1px solid #e2e8f0',
                  borderRadius: '8px'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div>
                      <div style={{ fontWeight: 'bold', marginBottom: '0.5rem' }}>
                        {source.title}
                      </div>
                      <a
                        href={source.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ color: '#3182ce', fontSize: '0.875rem', textDecoration: 'none' }}
                      >
                        {source.domain}
                      </a>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontWeight: 'bold', color: '#d69e2e' }}>
                        {source.match_count} совпадений
                      </div>
                      <div style={{ fontSize: '0.875rem', color: '#718096' }}>
                        Схожесть: {(source.avg_similarity * 100).toFixed(0)}%
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Matches */}
        {result.matches && result.matches.length > 0 && (
          <div style={{
            background: 'white',
            borderRadius: '16px',
            padding: '2rem',
            boxShadow: '0 4px 12px rgba(0,0,0,0.05)'
          }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>
              🔍 Совпадения в тексте
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {result.matches.map((match, i) => (
                <div key={i} style={{
                  padding: '0.75rem',
                  background: match.type === 'lexical' ? '#fed7d7' : '#feebc8',
                  borderLeft: `4px solid ${match.type === 'lexical' ? '#e53e3e' : '#d69e2e'}`,
                  borderRadius: '4px'
                }}>
                  <div style={{ fontSize: '0.875rem', color: '#4a5568', marginBottom: '0.25rem' }}>
                    {match.type === 'lexical' ? '📝 Лексическое' : '🧠 Семантическое'} совпадение
                    • Схожесть: {(match.similarity * 100).toFixed(0)}%
                  </div>
                  <div style={{ fontStyle: 'italic' }}>
                    "{match.text}"
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Actions */}
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          gap: '1rem',
          marginTop: '2rem'
        }}>
          <button
            onClick={() => router.push('/')}
            style={{
              padding: '0.75rem 2rem',
              background: '#3182ce',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            Новая проверка
          </button>
          <button
            onClick={() => window.print()}
            style={{
              padding: '0.75rem 2rem',
              background: 'white',
              color: '#3182ce',
              border: '2px solid #3182ce',
              borderRadius: '8px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            📄 Скачать PDF
          </button>
        </div>
      </div>

      <style jsx>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  )
}