# Скрипт аудита проекта AI Text Detector
Write-Host "Начинаем аудит проекта..." -ForegroundColor Cyan
Write-Host ""

# Путь для сохранения отчета
$outputFile = "project-audit.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Очищаем файл
"" | Out-File $outputFile -Encoding UTF8

# Функция для добавления содержимого файла
function Add-FileContent {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        "`n" + "="*80 | Out-File $outputFile -Append -Encoding UTF8
        "[OK] $Description" | Out-File $outputFile -Append -Encoding UTF8
        "Path: $FilePath" | Out-File $outputFile -Append -Encoding UTF8
        "="*80 | Out-File $outputFile -Append -Encoding UTF8
        Get-Content $FilePath -Raw -Encoding UTF8 | Out-File $outputFile -Append -Encoding UTF8
        Write-Host "[OK] $Description" -ForegroundColor Green
    } else {
        "`n" + "="*80 | Out-File $outputFile -Append -Encoding UTF8
        "[NOT FOUND] $Description" | Out-File $outputFile -Append -Encoding UTF8
        "Path: $FilePath" | Out-File $outputFile -Append -Encoding UTF8
        "FILE NOT FOUND" | Out-File $outputFile -Append -Encoding UTF8
        "="*80 | Out-File $outputFile -Append -Encoding UTF8
        Write-Host "[MISSING] $Description" -ForegroundColor Red
    }
}

# Заголовок отчета
@"
================================================================================
           AUDIT REPORT: AI TEXT DETECTOR PROJECT
           Date: $timestamp
================================================================================
"@ | Out-File $outputFile -Append -Encoding UTF8

# BACKEND
Write-Host "`n=== BACKEND FILES ===" -ForegroundColor Yellow
Add-FileContent "backend\public-api\app\main.py" "Backend Main (FastAPI)"
Add-FileContent "backend\public-api\app\core\config.py" "Backend Config"
Add-FileContent "backend\public-api\app\core\__init__.py" "Backend Core Init"
Add-FileContent "backend\public-api\app\services\ai.py" "AI Detection Service"
Add-FileContent "backend\public-api\app\services\__init__.py" "Backend Services Init"
Add-FileContent "backend\public-api\app\__init__.py" "Backend App Init"
Add-FileContent "backend\public-api\app\models.py" "Database Models"
Add-FileContent "backend\public-api\requirements.txt" "Python Dependencies"
Add-FileContent "backend\public-api\pyproject.toml" "Python Project Config"
Add-FileContent "backend\public-api\.env" "Backend Environment"
Add-FileContent "backend\public-api\.env.example" "Backend Env Example"

# FRONTEND
Write-Host "`n=== FRONTEND FILES ===" -ForegroundColor Yellow
Add-FileContent "frontend\app\page.tsx" "Home Page"
Add-FileContent "frontend\app\layout.tsx" "Root Layout"
Add-FileContent "frontend\app\report\[id]\page.tsx" "Report Page"
Add-FileContent "frontend\lib\api.ts" "API Client"
Add-FileContent "frontend\package.json" "NPM Dependencies"
Add-FileContent "frontend\next.config.js" "Next.js Config"
Add-FileContent "frontend\tailwind.config.js" "Tailwind Config"
Add-FileContent "frontend\tsconfig.json" "TypeScript Config"
Add-FileContent "frontend\.env.local" "Frontend Environment Local"
Add-FileContent "frontend\.env" "Frontend Environment"
Add-FileContent "frontend\.env.example" "Frontend Env Example"

# CONFIG
Write-Host "`n=== CONFIG FILES ===" -ForegroundColor Yellow
Add-FileContent "docker-compose.yml" "Docker Compose"
Add-FileContent "render.yaml" "Render Deployment"
Add-FileContent ".env.example" "Root Env Example"
Add-FileContent ".gitignore" "Git Ignore"
Add-FileContent "README.md" "README"

# API GATEWAY
Write-Host "`n=== API GATEWAY ===" -ForegroundColor Yellow
Add-FileContent "backend\api-gateway\main.go" "API Gateway (Go)"
Add-FileContent "backend\api-gateway\go.mod" "Go Dependencies"

# Структура проекта
Write-Host "`n=== PROJECT STRUCTURE ===" -ForegroundColor Yellow
"`n" + "="*80 | Out-File $outputFile -Append -Encoding UTF8
"PROJECT STRUCTURE" | Out-File $outputFile -Append -Encoding UTF8
"="*80 | Out-File $outputFile -Append -Encoding UTF8
tree /F /A | Out-File $outputFile -Append -Encoding UTF8

# Завершение
Write-Host "`n=== AUDIT COMPLETED ===" -ForegroundColor Green
Write-Host "Report saved to: $outputFile" -ForegroundColor Cyan
Write-Host "`nPlease copy the content and send for analysis" -ForegroundColor Yellow
Write-Host ""

# Открыть файл в блокноте
$openFile = Read-Host "Open report in notepad? (y/n)"
if ($openFile -eq "y") {
    notepad $outputFile
}