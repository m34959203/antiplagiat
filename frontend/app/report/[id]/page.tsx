'use client'

import { useParams, useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

// Определяем интерфейсы для данных
interface Match {
  text: string
  source_id: number
}
interface Source {
  id: number
  title: string
  url: string
}
interface CheckResult {
  originality: number
  total_words: number
  created_at: string
  matches: Match[]
  sources: Source[]
  checked_text?: string // Добавим поле для исходного текста
}

export default function ReportPage() {
  const params = useParams()
  const [result, setResult] = useState<CheckResult | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!params.id) return

    const fetchResult = async () => {
      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://antiplagiat-api.onrender.com'
        const response = await fetch(`${apiUrl}/api/v1/check/${params.id}`)
        if (!response.ok) throw new Error('Result not found')
        const data = await response.json()
        setResult(data)
      } catch (error) {
        console.error(error)
      } finally {
        setLoading(false)
      }
    }
    fetchResult()
  }, [params.id])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-100">
        <p className="text-lg">Загрузка отчета...</p>
      </div>
    )
  }

  if (!result) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-100">
        <p className="text-lg text-red-500">Отчет не найден.</p>
      </div>
    )
  }
  
  // Форматирование источников совпадений
  const renderSources = () => {
    if (!result.sources || result.sources.length === 0) {
      return "Совпадений не найдено"
    }
    return (
      <ul className="list-decimal pl-5">
        {result.sources.map(source => (
          <li key={source.id}>
            <a href={source.url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
              {source.title || source.url}
            </a>
          </li>
        ))}
      </ul>
    )
  }

  return (
    <div className="min-h-screen bg-gray-100 py-10 px-4">
      <div className="max-w-4xl mx-auto">
        <div id="report-content" className="bg-white p-8 sm:p-12 border border-gray-300 shadow-lg">
          <h1 className="text-center text-xl font-bold mb-6">СПРАВКА</h1>
          <p className="text-center text-base mb-8">
            о результатах проверки текстового документа на уникальность
          </p>

          <div className="space-y-3 text-sm mb-10">
            <p><span className="font-semibold">Проверка выполнена в системе:</span> ANTIPLAGIAT</p>
            <p><span className="font-semibold">Дата и время проверки:</span> {new Date(result.created_at).toLocaleString('ru-RU')}</p>
            <p><span className="font-semibold">Процент уникальности:</span> {result.originality.toFixed(2)}%</p>
            <p><span className="font-semibold">Количество слов:</span> {result.total_words}</p>
          </div>

          <div className="my-10 text-center">
            <p className="text-6xl font-bold text-green-600">{result.originality.toFixed(2)}%</p>
          </div>

          <div className="mb-10">
            <h2 className="font-semibold mb-2">Источники совпадений:</h2>
            <div className="text-sm">{renderSources()}</div>
          </div>
          
          {result.checked_text && (
            <div>
              <h2 className="font-semibold mb-4">Проверенный текст</h2>
              <div className="p-4 bg-gray-50 border rounded text-sm whitespace-pre-wrap">
                {result.checked_text}
              </div>
            </div>
          )}
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={() => window.print()}
            className="bg-blue-600 text-white font-semibold py-2 px-6 rounded-lg hover:bg-blue-700 transition"
          >
            🖨️ Печать
          </button>
        </div>
      </div>
    </div>
  )
}
