# analyze-code.ps1
# Анализ качества кода

Write-Host "🔍 Анализ кодовой базы..." -ForegroundColor Cyan

$stats = @{
    TotalFiles = 0
    TotalLines = 0
    Python = @{ Files = 0; Lines = 0 }
    TypeScript = @{ Files = 0; Lines = 0 }
    JavaScript = @{ Files = 0; Lines = 0 }
    Go = @{ Files = 0; Lines = 0 }
    Config = @{ Files = 0; Lines = 0 }
}

# Python файлы
Get-ChildItem -Path "backend" -Filter "*.py" -Recurse | ForEach-Object {
    if ($_.FullName -notmatch '__pycache__|\.venv|venv') {
        $lines = (Get-Content $_.FullName).Count
        $stats.Python.Files++
        $stats.Python.Lines += $lines
        $stats.TotalFiles++
        $stats.TotalLines += $lines
    }
}

# TypeScript/JavaScript
Get-ChildItem -Path "frontend" -Include "*.ts","*.tsx","*.js","*.jsx" -Recurse | ForEach-Object {
    if ($_.FullName -notmatch 'node_modules|\.next') {
        $lines = (Get-Content $_.FullName).Count
        if ($_.Extension -match '\.tsx?$') {
            $stats.TypeScript.Files++
            $stats.TypeScript.Lines += $lines
        } else {
            $stats.JavaScript.Files++
            $stats.JavaScript.Lines += $lines
        }
        $stats.TotalFiles++
        $stats.TotalLines += $lines
    }
}

# Go файлы
Get-ChildItem -Path "backend/api-gateway" -Filter "*.go" -Recurse | ForEach-Object {
    $lines = (Get-Content $_.FullName).Count
    $stats.Go.Files++
    $stats.Go.Lines += $lines
    $stats.TotalFiles++
    $stats.TotalLines += $lines
}

# Вывод
Write-Host ""
Write-Host "📊 СТАТИСТИКА КОДА" -ForegroundColor Green
Write-Host "=" * 50
Write-Host ""
Write-Host "🐍 Python:" -ForegroundColor Yellow
Write-Host "   Файлов: $($stats.Python.Files)"
Write-Host "   Строк: $($stats.Python.Lines)"
Write-Host ""
Write-Host "📘 TypeScript:" -ForegroundColor Blue
Write-Host "   Файлов: $($stats.TypeScript.Files)"
Write-Host "   Строк: $($stats.TypeScript.Lines)"
Write-Host ""
Write-Host "🔷 Go:" -ForegroundColor Cyan
Write-Host "   Файлов: $($stats.Go.Files)"
Write-Host "   Строк: $($stats.Go.Lines)"
Write-Host ""
Write-Host "📊 ИТОГО:" -ForegroundColor Green
Write-Host "   Файлов: $($stats.TotalFiles)"
Write-Host "   Строк кода: $($stats.TotalLines)"
Write-Host ""

# Сохраняем в файл
$stats | ConvertTo-Json | Out-File "CODE-STATS.json"
Write-Host "✅ Сохранено в CODE-STATS.json" -ForegroundColor Green