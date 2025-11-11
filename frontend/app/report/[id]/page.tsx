'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'

interface CheckResult {
  task_id: string
  status: string
  originality: number
  total_words: number
  total_chars: number
  matches: Array<{
    start: number
    end: number
    text: string
    source_id: number
    similarity: number
    type: string
  }>
  sources: Array<{
    id: number
    title: string
    url: string
    domain: string
    match_count: number
  }>
  ai_powered: boolean
  created_at: string
}

export default function ReportPage() {
  const params = useParams()
  const router = useRouter()
  const taskId = params.id as string
  
  const [result, setResult] = useState<CheckResult | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchResult = async () => {
      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'
        const response = await fetch(`${apiUrl}/api/v1/check/${taskId}`)
        
        if (!response.ok) {
          throw new Error(`Failed to fetch: ${response.status}`)
        }
        
        const data = await response.json()
        setResult(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    if (taskId) {
      fetchResult()
    }
  }, [taskId])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-700 text-lg">Р—Р°РіСЂСѓР·РєР° СЂРµР·СѓР»СЊС‚Р°С‚РѕРІ...</p>
        </div>
      </div>
    )
  }

  if (error || !result) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-red-50 to-pink-100">
        <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md">
          <div className="text-red-600 text-6xl mb-4 text-center">вљ пёЏ</div>
          <h2 className="text-red-800 text-2xl font-bold mb-3 text-center">РћС€РёР±РєР°</h2>
          <p className="text-red-600 text-center mb-6">{error || 'Р РµР·СѓР»СЊС‚Р°С‚ РЅРµ РЅР°Р№РґРµРЅ'}</p>
          <button 
            onClick={() => router.push('/')}
            className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 transition font-semibold"
          >
            в†ђ Р’РµСЂРЅСѓС‚СЊСЃСЏ РЅР° РіР»Р°РІРЅСѓСЋ
          </button>
        </div>
      </div>
    )
  }

  const getOriginalityColor = (score: number) => {
    if (score >= 80) return 'text-green-600'
    if (score >= 60) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getOriginalityBg = (score: number) => {
    if (score >= 80) return 'from-green-50 to-emerald-100'
    if (score >= 60) return 'from-yellow-50 to-amber-100'
    return 'from-red-50 to-pink-100'
  }

  return (
    <div className={`min-h-screen bg-gradient-to-br ${getOriginalityBg(result.originality)} py-12 px-4`}>
      <div className="max-w-5xl mx-auto">
        <div className="bg-white rounded-2xl shadow-2xl p-8 mb-8">
          <div className="text-center">
            <h1 className="text-4xl font-bold mb-3 bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
              Р РµР·СѓР»СЊС‚Р°С‚ РїСЂРѕРІРµСЂРєРё
            </h1>
            <p className="text-gray-400 text-sm font-mono">ID: {result.task_id}</p>
          </div>

          <div className="mt-10 text-center relative">
            <div className="inline-block relative">
              <div className={`text-8xl font-black ${getOriginalityColor(result.originality)} drop-shadow-lg`}>
                {result.originality.toFixed(1)}%
              </div>
              <div className="absolute -top-4 -right-4">
                {result.ai_powered && (
                  <span className="bg-gradient-to-r from-purple-500 to-pink-500 text-white text-xs px-3 py-1 rounded-full font-bold shadow-lg">
                    рџ¤– AI
                  </span>
                )}
              </div>
            </div>
            <p className="text-gray-600 mt-4 text-lg font-semibold">РћСЂРёРіРёРЅР°Р»СЊРЅРѕСЃС‚СЊ С‚РµРєСЃС‚Р°</p>
          </div>

          <div className="grid grid-cols-3 gap-6 mt-10">
            <div className="text-center p-6 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="text-3xl font-bold text-blue-700">{result.total_words}</div>
              <div className="text-blue-600 text-sm mt-2 font-semibold">РЎР»РѕРІ</div>
            </div>
            <div className="text-center p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl border border-purple-200">
              <div className="text-3xl font-bold text-purple-700">{result.total_chars}</div>
              <div className="text-purple-600 text-sm mt-2 font-semibold">РЎРёРјРІРѕР»РѕРІ</div>
            </div>
            <div className="text-center p-6 bg-gradient-to-br from-red-50 to-red-100 rounded-xl border border-red-200">
              <div className="text-3xl font-bold text-red-700">{result.matches?.length || 0}</div>
              <div className="text-red-600 text-sm mt-2 font-semibold">РЎРѕРІРїР°РґРµРЅРёР№</div>
            </div>
          </div>

          <div className="mt-6 text-center text-sm text-gray-500">
            РџСЂРѕРІРµСЂРµРЅРѕ: {new Date(result.created_at).toLocaleString('ru-RU')}
          </div>
        </div>

        {result.matches && result.matches.length > 0 && (
          <div className="bg-white rounded-2xl shadow-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold mb-6 flex items-center gap-3">
              <span className="text-3xl">рџ”Ќ</span>
              РќР°Р№РґРµРЅРЅС‹Рµ СЃРѕРІРїР°РґРµРЅРёСЏ
            </h2>
            <div className="space-y-4">
              {result.matches.slice(0, 10).map((match, index) => (
                <div key={index} className="border-l-4 border-red-500 bg-red-50 pl-6 pr-4 py-4 rounded-r-lg hover:bg-red-100 transition">
                  <p className="text-gray-800 leading-relaxed">&quot;{match.text}&quot;</p>
                  <div className="flex gap-6 mt-3 text-sm">
                    <span className="bg-red-200 text-red-800 px-3 py-1 rounded-full font-semibold">
                      РЎС…РѕРґСЃС‚РІРѕ: {(match.similarity * 100).toFixed(0)}%
                    </span>
                    <span className="bg-gray-200 text-gray-700 px-3 py-1 rounded-full font-semibold">
                      {match.type}
                    </span>
                  </div>
                </div>
              ))}
            </div>
            {result.matches.length > 10 && (
              <p className="text-center text-gray-500 mt-6">
                ... Рё РµС‰Рµ {result.matches.length - 10} СЃРѕРІРїР°РґРµРЅРёР№
              </p>
            )}
          </div>
        )}

        {result.sources && result.sources.length > 0 && (
          <div className="bg-white rounded-2xl shadow-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold mb-6 flex items-center gap-3">
              <span className="text-3xl">рџ”—</span>
              РСЃС‚РѕС‡РЅРёРєРё
            </h2>
            <div className="space-y-4">
              {result.sources.map((source, index) => (
                <div key={source.id} className="border-b pb-4 last:border-b-0 hover:bg-gray-50 p-4 rounded-lg transition">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs font-bold">
                          #{index + 1}
                        </span>
                        <a 
                          href={source.url} 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="text-blue-600 hover:text-blue-800 font-semibold hover:underline flex-1"
                        >
                          {source.title || source.url}
                        </a>
                      </div>
                      <div className="text-sm text-gray-600 flex items-center gap-3">
                        <span className="font-mono bg-gray-100 px-2 py-1 rounded">{source.domain}</span>
                        <span className="text-gray-400">вЂў</span>
                        <span className="bg-red-100 text-red-700 px-2 py-1 rounded font-semibold">
                          {source.match_count} СЃРѕРІРїР°РґРµРЅРёР№
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {(!result.matches || result.matches.length === 0) && (
          <div className="bg-white rounded-2xl shadow-2xl p-12 mb-8 text-center">
            <div className="text-6xl mb-4">вњ…</div>
            <h3 className="text-2xl font-bold text-green-700 mb-2">РћС‚Р»РёС‡РЅС‹Р№ СЂРµР·СѓР»СЊС‚Р°С‚!</h3>
            <p className="text-gray-600">РЎРѕРІРїР°РґРµРЅРёР№ РЅРµ РѕР±РЅР°СЂСѓР¶РµРЅРѕ. РўРµРєСЃС‚ СѓРЅРёРєР°Р»РµРЅ.</p>
          </div>
        )}

        <div className="flex gap-4 justify-center">
          <button 
            onClick={() => router.push('/')}
            className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-8 py-4 rounded-xl hover:from-blue-700 hover:to-indigo-700 transition shadow-lg font-semibold text-lg"
          >
            в†ђ РќРѕРІР°СЏ РїСЂРѕРІРµСЂРєР°
          </button>
          <button 
            onClick={() => window.print()}
            className="bg-white border-2 border-gray-300 text-gray-700 px-8 py-4 rounded-xl hover:bg-gray-50 transition shadow-lg font-semibold text-lg"
          >
            рџ–ЁпёЏ РџРµС‡Р°С‚СЊ
          </button>
        </div>
      </div>
    </div>
  )
}
