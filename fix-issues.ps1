<#
.SYNOPSIS
    Auto-fix all issues found by inspection
#>

$ErrorActionPreference = 'Continue'
$projectRoot = $PSScriptRoot

Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "                   AUTO-FIX ANTIPLAGIAT ISSUES                          " -ForegroundColor Cyan
Write-Host "========================================================================`n" -ForegroundColor Cyan

# ============================================================================
# 1. CREATE MISSING REPORT PAGE
# ============================================================================

Write-Host "[1/4] Creating missing report page..." -ForegroundColor Yellow

$reportDir = Join-Path $projectRoot "frontend\app\report"
$reportIdDir = Join-Path $reportDir "[id]"

if (-not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $reportIdDir)) {
    New-Item -ItemType Directory -LiteralPath $reportIdDir -Force | Out-Null
}

$reportFile = Join-Path $reportIdDir "page.tsx"

$reportPageContent = @'
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
          <p className="text-gray-700 text-lg">Загрузка результатов...</p>
        </div>
      </div>
    )
  }

  if (error || !result) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-red-50 to-pink-100">
        <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md">
          <div className="text-red-600 text-6xl mb-4 text-center">⚠️</div>
          <h2 className="text-red-800 text-2xl font-bold mb-3 text-center">Ошибка</h2>
          <p className="text-red-600 text-center mb-6">{error || 'Результат не найден'}</p>
          <button 
            onClick={() => router.push('/')}
            className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 transition font-semibold"
          >
            ← Вернуться на главную
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
              Результат проверки
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
                    🤖 AI
                  </span>
                )}
              </div>
            </div>
            <p className="text-gray-600 mt-4 text-lg font-semibold">Оригинальность текста</p>
          </div>

          <div className="grid grid-cols-3 gap-6 mt-10">
            <div className="text-center p-6 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="text-3xl font-bold text-blue-700">{result.total_words}</div>
              <div className="text-blue-600 text-sm mt-2 font-semibold">Слов</div>
            </div>
            <div className="text-center p-6 bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl border border-purple-200">
              <div className="text-3xl font-bold text-purple-700">{result.total_chars}</div>
              <div className="text-purple-600 text-sm mt-2 font-semibold">Символов</div>
            </div>
            <div className="text-center p-6 bg-gradient-to-br from-red-50 to-red-100 rounded-xl border border-red-200">
              <div className="text-3xl font-bold text-red-700">{result.matches?.length || 0}</div>
              <div className="text-red-600 text-sm mt-2 font-semibold">Совпадений</div>
            </div>
          </div>

          <div className="mt-6 text-center text-sm text-gray-500">
            Проверено: {new Date(result.created_at).toLocaleString('ru-RU')}
          </div>
        </div>

        {result.matches && result.matches.length > 0 && (
          <div className="bg-white rounded-2xl shadow-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold mb-6 flex items-center gap-3">
              <span className="text-3xl">🔍</span>
              Найденные совпадения
            </h2>
            <div className="space-y-4">
              {result.matches.slice(0, 10).map((match, index) => (
                <div key={index} className="border-l-4 border-red-500 bg-red-50 pl-6 pr-4 py-4 rounded-r-lg hover:bg-red-100 transition">
                  <p className="text-gray-800 leading-relaxed">&quot;{match.text}&quot;</p>
                  <div className="flex gap-6 mt-3 text-sm">
                    <span className="bg-red-200 text-red-800 px-3 py-1 rounded-full font-semibold">
                      Сходство: {(match.similarity * 100).toFixed(0)}%
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
                ... и еще {result.matches.length - 10} совпадений
              </p>
            )}
          </div>
        )}

        {result.sources && result.sources.length > 0 && (
          <div className="bg-white rounded-2xl shadow-2xl p-8 mb-8">
            <h2 className="text-3xl font-bold mb-6 flex items-center gap-3">
              <span className="text-3xl">🔗</span>
              Источники
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
                        <span className="text-gray-400">•</span>
                        <span className="bg-red-100 text-red-700 px-2 py-1 rounded font-semibold">
                          {source.match_count} совпадений
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
            <div className="text-6xl mb-4">✅</div>
            <h3 className="text-2xl font-bold text-green-700 mb-2">Отличный результат!</h3>
            <p className="text-gray-600">Совпадений не обнаружено. Текст уникален.</p>
          </div>
        )}

        <div className="flex gap-4 justify-center">
          <button 
            onClick={() => router.push('/')}
            className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-8 py-4 rounded-xl hover:from-blue-700 hover:to-indigo-700 transition shadow-lg font-semibold text-lg"
          >
            ← Новая проверка
          </button>
          <button 
            onClick={() => window.print()}
            className="bg-white border-2 border-gray-300 text-gray-700 px-8 py-4 rounded-xl hover:bg-gray-50 transition shadow-lg font-semibold text-lg"
          >
            🖨️ Печать
          </button>
        </div>
      </div>
    </div>
  )
}
'@

Set-Content -LiteralPath $reportFile -Value $reportPageContent -Encoding UTF8
Write-Host "  [OK] Created: frontend\app\report\[id]\page.tsx" -ForegroundColor Green

# ============================================================================
# 2. REMOVE PRINT STATEMENTS
# ============================================================================

Write-Host "`n[2/4] Removing print statements from Python files..." -ForegroundColor Yellow

$backendPath = Join-Path $projectRoot "backend\public-api\app"
if (Test-Path $backendPath) {
    $pythonFiles = Get-ChildItem -Path $backendPath -Filter "*.py" -Recurse

    $printCount = 0
    $totalPrints = 0
    
    foreach ($file in $pythonFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -Encoding UTF8
            
            # Skip empty files
            if ([string]::IsNullOrWhiteSpace($content)) {
                continue
            }
            
            # Count prints
            $matches = [regex]::Matches($content, 'print\(')
            $prints = $matches.Count
            
            if ($prints -gt 0) {
                $totalPrints += $prints
                
                # Replace print() with logger.info()
                $newContent = $content -replace 'print\(([^)]+)\)', 'logger.info($1)'
                
                # Add logging import if not present
                if ($newContent -notmatch 'import logging') {
                    # Find first import statement
                    $lines = $newContent -split "`r?`n"
                    $insertIndex = 0
                    
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match '^(from |import )' -and $insertIndex -eq 0) {
                            $insertIndex = $i
                            break
                        }
                    }
                    
                    if ($insertIndex -gt 0) {
                        # Insert after first import
                        $beforeImport = $lines[0..$insertIndex]
                        $afterImport = $lines[($insertIndex + 1)..($lines.Count - 1)]
                        
                        $newLines = $beforeImport + @('import logging', 'logger = logging.getLogger(__name__)', '') + $afterImport
                        $newContent = $newLines -join "`n"
                    } else {
                        # Insert at beginning
                        $newContent = "import logging`nlogger = logging.getLogger(__name__)`n`n" + $newContent
                    }
                }
                
                Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
                $printCount++
                Write-Host "  [OK] Fixed $prints prints in: $($file.Name)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  [!!] Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($printCount -eq 0) {
        Write-Host "  [OK] No print statements found" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Fixed $totalPrints print statements in $printCount files" -ForegroundColor Green
    }
}

# ============================================================================
# 3. UPDATE ENV EXAMPLES
# ============================================================================

Write-Host "`n[3/4] Updating .env.example files..." -ForegroundColor Yellow

# Backend .env.example
$backendEnv = Join-Path $projectRoot "backend\public-api\.env.example"
if (Test-Path $backendEnv) {
    $envContent = Get-Content $backendEnv -Raw
    
    $updated = $false
    
    if ($envContent -notmatch 'GOOGLE_SEARCH_API_KEY') {
        Add-Content $backendEnv "`nGOOGLE_SEARCH_API_KEY=your_google_api_key_here" -NoNewline
        Write-Host "  [OK] Added GOOGLE_SEARCH_API_KEY to backend .env.example" -ForegroundColor Green
        $updated = $true
    }
    
    if ($envContent -notmatch 'GOOGLE_SEARCH_CX') {
        Add-Content $backendEnv "`nGOOGLE_SEARCH_CX=your_search_engine_id_here" -NoNewline
        Write-Host "  [OK] Added GOOGLE_SEARCH_CX to backend .env.example" -ForegroundColor Green
        $updated = $true
    }
    
    if (-not $updated) {
        Write-Host "  [OK] Backend .env.example already up to date" -ForegroundColor Green
    }
}

# Frontend .env.example
$frontendEnv = Join-Path $projectRoot "frontend\.env.example"
if (-not (Test-Path $frontendEnv)) {
    "NEXT_PUBLIC_API_URL=http://localhost:8000" | Out-File -FilePath $frontendEnv -Encoding UTF8 -NoNewline
    Write-Host "  [OK] Created frontend .env.example" -ForegroundColor Green
} else {
    $envContent = Get-Content $frontendEnv -Raw
    if ($envContent -notmatch 'NEXT_PUBLIC_API_URL') {
        Add-Content $frontendEnv "`nNEXT_PUBLIC_API_URL=http://localhost:8000" -NoNewline
        Write-Host "  [OK] Updated frontend .env.example" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Frontend .env.example already up to date" -ForegroundColor Green
    }
}

# ============================================================================
# 4. RUN INSPECTION AGAIN
# ============================================================================

Write-Host "`n[4/4] Running inspection again..." -ForegroundColor Yellow

$inspectScript = Join-Path $projectRoot "inspect-project.ps1"
if (Test-Path $inspectScript) {
    Write-Host ""
    & $inspectScript
}

Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "                         FIX COMPLETED!                                 " -ForegroundColor Cyan
Write-Host "========================================================================`n" -ForegroundColor Cyan

Write-Host "Summary of changes:" -ForegroundColor Yellow
Write-Host "  - Created report page: frontend/app/report/[id]/page.tsx" -ForegroundColor Green
Write-Host "  - Removed $totalPrints print statements from $printCount files" -ForegroundColor Green
Write-Host "  - Updated .env.example files" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review: " -NoNewline -ForegroundColor White
Write-Host "git diff" -ForegroundColor Cyan
Write-Host "  2. Test: " -NoNewline -ForegroundColor White
Write-Host "cd frontend && npm run dev" -ForegroundColor Cyan
Write-Host "  3. Commit: " -NoNewline -ForegroundColor White
Write-Host "git add . && git commit -m 'fix: auto-fix issues (report page, logging)'" -ForegroundColor Cyan
Write-Host "  4. Push: " -NoNewline -ForegroundColor White
Write-Host "git push" -ForegroundColor Cyan
Write-Host ""