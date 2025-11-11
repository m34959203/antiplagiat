<#
.SYNOPSIS
    Antiplagiat Project Inspector
#>

param(
    [switch]$OpenHTML
)

$ErrorActionPreference = 'SilentlyContinue'
$projectRoot = $PSScriptRoot
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDir = Join-Path $projectRoot "inspection-reports"

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

# Colors
function Write-Section { param([string]$Title)
    Write-Host "`n$('='*80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $('='*80) -ForegroundColor Cyan
}

function Write-SubSection { param([string]$Title)
    Write-Host "`n  >> $Title" -ForegroundColor Yellow
    Write-Host "  $('-'*70)" -ForegroundColor DarkGray
}

function Write-OK { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-WARN { param([string]$Msg) Write-Host "  [!!] $Msg" -ForegroundColor Yellow }
function Write-ERR { param([string]$Msg) Write-Host "  [XX] $Msg" -ForegroundColor Red }
function Write-INF { param([string]$Msg) Write-Host "  [--] $Msg" -ForegroundColor Cyan }

# Global report
$global:report = @{
    timestamp = $timestamp
    critical = @()
    warnings = @()
    metrics = @{}
    structure = @{}
    code = @{}
    security = @{}
}

# ============================================================================
# 1. PROJECT STRUCTURE
# ============================================================================

function Test-ProjectStructure {
    Write-Section "1. PROJECT STRUCTURE"
    
    $paths = @(
        'backend\public-api\app\main.py',
        'backend\public-api\app\models.py',
        'backend\public-api\app\core\config.py',
        'backend\public-api\app\services\detector.py',
        'backend\public-api\app\services\ai.py',
        'backend\public-api\requirements.txt',
        'frontend\app\page.tsx',
        'frontend\app\layout.tsx',
        'frontend\lib\api.ts',
        'frontend\package.json',
        'docker-compose.yml',
        'render.yaml',
        'README.md',
        'docs\API.md',
        'docs\ARCHITECTURE.md',
        'docs\DEPLOYMENT.md'
    )
    
    $found = 0
    $missing = 0
    
    foreach ($path in $paths) {
        $fullPath = Join-Path $projectRoot $path
        if (Test-Path $fullPath) {
            Write-OK $path
            $found++
        } else {
            Write-ERR "Missing: $path"
            $missing++
            $global:report.critical += "Missing file: $path"
        }
    }
    
    $global:report.structure = @{
        found = $found
        missing = $missing
        total = $paths.Count
    }
    
    Write-INF "Found: $found / $($paths.Count)"
}

# ============================================================================
# 2. DEPENDENCIES
# ============================================================================

function Test-Dependencies {
    Write-Section "2. DEPENDENCIES"
    
    Write-SubSection "Python"
    
    try {
        $pythonVer = python --version 2>&1
        Write-OK "Python: $pythonVer"
        $global:report.metrics['python'] = $pythonVer
    } catch {
        Write-ERR "Python not found"
        $global:report.critical += "Python not installed"
    }
    
    # Check requirements.txt
    $reqFile = Join-Path $projectRoot "backend\public-api\requirements.txt"
    if (Test-Path $reqFile) {
        $reqs = Get-Content $reqFile
        Write-INF "Requirements: $($reqs.Count) packages"
        
        $needed = @('fastapi', 'sqlalchemy', 'httpx')
        foreach ($pkg in $needed) {
            $found = $reqs | Where-Object { $_ -like "$pkg*" }
            if ($found) {
                Write-OK "  $pkg"
            } else {
                Write-WARN "  $pkg missing"
            }
        }
    }
    
    Write-SubSection "Node.js"
    
    try {
        $nodeVer = node --version 2>&1
        Write-OK "Node.js: $nodeVer"
        $global:report.metrics['nodejs'] = $nodeVer
    } catch {
        Write-ERR "Node.js not found"
        $global:report.critical += "Node.js not installed"
    }
    
    # Check package.json
    $pkgFile = Join-Path $projectRoot "frontend\package.json"
    if (Test-Path $pkgFile) {
        $pkg = Get-Content $pkgFile | ConvertFrom-Json
        Write-INF "Package: $($pkg.name) v$($pkg.version)"
        
        $needed = @('next', 'react', 'typescript')
        foreach ($dep in $needed) {
            if ($pkg.dependencies.$dep -or $pkg.devDependencies.$dep) {
                Write-OK "  $dep"
            } else {
                Write-WARN "  $dep missing"
            }
        }
    }
}

# ============================================================================
# 3. CONFIGURATIONS
# ============================================================================

function Test-Configurations {
    Write-Section "3. CONFIGURATIONS"
    
    Write-SubSection "Environment Files"
    
    $envFiles = @(
        'backend\public-api\.env.example',
        'frontend\.env.example'
    )
    
    foreach ($file in $envFiles) {
        $fullPath = Join-Path $projectRoot $file
        if (Test-Path $fullPath) {
            Write-OK $file
            
            $content = Get-Content $fullPath -Raw
            $vars = @('DATABASE_URL', 'GOOGLE_SEARCH_API_KEY', 'OPENROUTER_API_KEY')
            foreach ($var in $vars) {
                if ($content -match $var) {
                    Write-INF "    $var OK"
                } else {
                    Write-WARN "    $var missing"
                }
            }
        } else {
            Write-ERR "$file missing"
        }
    }
    
    Write-SubSection "Docker & Deployment"
    
    $configs = @('docker-compose.yml', 'render.yaml')
    foreach ($cfg in $configs) {
        $fullPath = Join-Path $projectRoot $cfg
        if (Test-Path $fullPath) {
            Write-OK $cfg
        } else {
            Write-WARN "$cfg missing"
        }
    }
}

# ============================================================================
# 4. CODE QUALITY
# ============================================================================

function Test-CodeQuality {
    Write-Section "4. CODE QUALITY"
    
    Write-SubSection "Backend (Python)"
    
    $pyPath = Join-Path $projectRoot "backend\public-api\app"
    if (Test-Path $pyPath) {
        $pyFiles = Get-ChildItem -Path $pyPath -Filter "*.py" -Recurse
        
        $todos = 0
        $prints = 0
        $loc = 0
        
        foreach ($file in $pyFiles) {
            $content = Get-Content $file.FullName -Raw
            $lines = Get-Content $file.FullName
            
            $loc += $lines.Count
            $todos += ([regex]::Matches($content, 'TODO')).Count
            $prints += ([regex]::Matches($content, 'print\(')).Count
        }
        
        Write-INF "Python files: $($pyFiles.Count)"
        Write-INF "Lines of code: $loc"
        Write-INF "TODO comments: $todos"
        
        if ($prints -gt 0) {
            Write-WARN "Print statements: $prints (remove for production)"
        } else {
            Write-OK "No print statements"
        }
        
        $global:report.code['python_loc'] = $loc
        $global:report.code['python_files'] = $pyFiles.Count
        $global:report.code['python_todos'] = $todos
        $global:report.code['python_prints'] = $prints
    }
    
    Write-SubSection "Frontend (TypeScript)"
    
    $frontPath = Join-Path $projectRoot "frontend"
    if (Test-Path $frontPath) {
        $tsFiles = Get-ChildItem -Path $frontPath -Include "*.tsx","*.ts" -Recurse | 
                   Where-Object { $_.FullName -notlike "*node_modules*" }
        
        $console = 0
        $loc = 0
        
        foreach ($file in $tsFiles) {
            $content = Get-Content $file.FullName -Raw
            $lines = Get-Content $file.FullName
            
            $loc += $lines.Count
            $console += ([regex]::Matches($content, 'console\.log')).Count
        }
        
        Write-INF "TypeScript files: $($tsFiles.Count)"
        Write-INF "Lines of code: $loc"
        
        if ($console -gt 0) {
            Write-WARN "console.log: $console (remove for production)"
        } else {
            Write-OK "No console.log"
        }
        
        $global:report.code['ts_loc'] = $loc
        $global:report.code['ts_files'] = $tsFiles.Count
        $global:report.code['ts_console'] = $console
    }
}

# ============================================================================
# 5. SECURITY
# ============================================================================

function Test-Security {
    Write-Section "5. SECURITY"
    
    Write-SubSection "Secrets Check"
    
    $issues = @()
    
    # Check .gitignore
    $gitignore = Join-Path $projectRoot ".gitignore"
    if (Test-Path $gitignore) {
        $content = Get-Content $gitignore -Raw
        
        $required = @('.env', 'node_modules', '__pycache__')
        foreach ($item in $required) {
            if ($content -match [regex]::Escape($item)) {
                Write-OK "  $item in .gitignore"
            } else {
                Write-WARN "  $item NOT in .gitignore"
                $issues += ".gitignore missing $item"
            }
        }
    } else {
        Write-ERR ".gitignore missing"
        $issues += ".gitignore not found"
    }
    
    Write-SubSection "CORS Configuration"
    
    $mainPy = Join-Path $projectRoot "backend\public-api\app\main.py"
    if (Test-Path $mainPy) {
        $content = Get-Content $mainPy -Raw
        
        if ($content -match 'CORSMiddleware') {
            Write-OK "CORS Middleware found"
            
            if ($content -match 'allow_origins.*\*') {
                Write-ERR "CORS allows ALL origins (*) - CRITICAL!"
                $issues += "CORS: wildcard origins unsafe"
                $global:report.critical += "CORS: allow_origins=['*']"
            } else {
                Write-OK "CORS properly configured"
            }
        } else {
            Write-WARN "CORS Middleware not found"
            $issues += "CORS not configured"
        }
    }
    
    $global:report.security['issues'] = $issues
    Write-INF "Security issues: $($issues.Count)"
}

# ============================================================================
# 6. CRITICAL CHECKS
# ============================================================================

function Test-CriticalIssues {
    Write-Section "6. CRITICAL ISSUES"
    
    $critical = @()
    
    # detector.py
    Write-SubSection "Detector Service"
    
    $detectorPath = Join-Path $projectRoot "backend\public-api\app\services\detector.py"
    if (Test-Path $detectorPath) {
        $content = Get-Content $detectorPath -Raw
        
        if ($content -match 'originality') {
            Write-OK "Originality calculation found"
        } else {
            Write-ERR "Originality calculation MISSING"
            $critical += "detector.py: no originality calculation"
        }
        
        if ($content -match 'google') {
            Write-OK "Google Search integration found"
        } else {
            Write-WARN "Google Search API not detected"
        }
    } else {
        Write-ERR "detector.py MISSING"
        $critical += "detector.py file not found"
    }
    
    # main.py
    Write-SubSection "Main Application"
    
    $mainPath = Join-Path $projectRoot "backend\public-api\app\main.py"
    if (Test-Path $mainPath) {
        $content = Get-Content $mainPath -Raw
        
        if ($content -match '/health') {
            Write-OK "/health endpoint found"
        } else {
            Write-WARN "/health endpoint missing"
        }
        
        if ($content -match '/api/v1/check') {
            Write-OK "/api/v1/check endpoint found"
        } else {
            Write-ERR "/api/v1/check endpoint MISSING"
            $critical += "main.py: /api/v1/check missing"
        }
    } else {
        Write-ERR "main.py MISSING"
        $critical += "main.py not found"
    }
    
    # Frontend report page
    Write-SubSection "Frontend Report Page"
    
    $reportPage = Join-Path $projectRoot "frontend\app\report\[id]\page.tsx"
    if (Test-Path -LiteralPath $reportPage) {
        Write-OK "report/[id]/page.tsx found"
    } else {
        Write-ERR "report/[id]/page.tsx MISSING"
        $critical += "Frontend: report page missing"
    }
    
    $global:report.critical += $critical
    
    if ($critical.Count -gt 0) {
        Write-Host ""
        Write-ERR "CRITICAL ISSUES FOUND: $($critical.Count)"
        foreach ($issue in $critical) {
            Write-ERR "  - $issue"
        }
    } else {
        Write-Host ""
        Write-OK "No critical issues found"
    }
}

# ============================================================================
# 7. GIT STATUS
# ============================================================================

function Test-GitStatus {
    Write-Section "7. GIT STATUS"
    
    Push-Location $projectRoot
    
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) {
            Write-INF "Branch: $branch"
            
            $status = git status --porcelain 2>$null
            if ($status) {
                $modified = ($status | Where-Object { $_ -match '^\s*M' }).Count
                $untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count
                
                if ($modified -gt 0) { Write-WARN "Modified files: $modified" }
                if ($untracked -gt 0) { Write-INF "Untracked files: $untracked" }
            } else {
                Write-OK "Working directory clean"
            }
            
            $lastCommit = git log -1 --pretty=format:"%h - %s (%cr)" 2>$null
            if ($lastCommit) {
                Write-INF "Last commit: $lastCommit"
            }
        } else {
            Write-ERR "Git repository not initialized"
        }
    }
    catch {
        Write-WARN "Git not available"
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# 8. DOCUMENTATION
# ============================================================================

function Test-Documentation {
    Write-Section "8. DOCUMENTATION"
    
    $docsPath = Join-Path $projectRoot "docs"
    if (Test-Path $docsPath) {
        $docs = Get-ChildItem -Path $docsPath -Filter "*.md"
        Write-INF "Documentation files: $($docs.Count)"
        
        $required = @('API.md', 'ARCHITECTURE.md', 'DEPLOYMENT.md', 'TECH_SPEC.md')
        foreach ($doc in $required) {
            $path = Join-Path $docsPath $doc
            if (Test-Path $path) {
                $size = [math]::Round((Get-Item $path).Length / 1KB, 2)
                Write-OK "$doc (${size} KB)"
            } else {
                Write-WARN "$doc missing"
            }
        }
    }
    
    $readme = Join-Path $projectRoot "README.md"
    if (Test-Path $readme) {
        $size = [math]::Round((Get-Item $readme).Length / 1KB, 2)
        Write-OK "README.md (${size} KB)"
    } else {
        Write-ERR "README.md missing"
    }
}

# ============================================================================
# 9. METRICS
# ============================================================================

function Get-ProjectMetrics {
    Write-Section "9. PROJECT METRICS"
    
    $pythonLoc = $global:report.code['python_loc']
    $tsLoc = $global:report.code['ts_loc']
    $totalLoc = $pythonLoc + $tsLoc
    
    Write-INF "Python LOC: $pythonLoc"
    Write-INF "TypeScript LOC: $tsLoc"
    Write-INF "Total LOC: $totalLoc"
    
    # Project size
    $allFiles = Get-ChildItem -Path $projectRoot -Recurse -File | 
                Where-Object { 
                    $_.FullName -notlike "*node_modules*" -and
                    $_.FullName -notlike "*__pycache__*" -and
                    $_.FullName -notlike "*.git*"
                }
    
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($totalSize / 1MB, 2)
    
    Write-INF "Project size: $sizeMB MB"
    Write-INF "Total files: $($allFiles.Count)"
    
    $global:report.metrics['total_loc'] = $totalLoc
    $global:report.metrics['size_mb'] = $sizeMB
    $global:report.metrics['files'] = $allFiles.Count
}

# ============================================================================
# 10. EXPORT REPORTS
# ============================================================================

function Export-Reports {
    Write-Section "10. GENERATING REPORTS"
    
    # Markdown Report
    $mdFile = Join-Path $reportDir "inspection-$timestamp.md"
    
    $md = @"
# Antiplagiat Project Inspection Report

**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary

- **Total LOC:** $($global:report.metrics['total_loc'])
- **Project Size:** $($global:report.metrics['size_mb']) MB
- **Files:** $($global:report.metrics['files'])
- **Critical Issues:** $($global:report.critical.Count)
- **Security Issues:** $($global:report.security['issues'].Count)

## Structure

- **Found:** $($global:report.structure['found']) / $($global:report.structure['total'])
- **Missing:** $($global:report.structure['missing'])

## Code Quality

### Backend (Python)
- Files: $($global:report.code['python_files'])
- LOC: $($global:report.code['python_loc'])
- TODOs: $($global:report.code['python_todos'])
- Print statements: $($global:report.code['python_prints'])

### Frontend (TypeScript)
- Files: $($global:report.code['ts_files'])
- LOC: $($global:report.code['ts_loc'])
- console.log: $($global:report.code['ts_console'])

## Critical Issues

$(if ($global:report.critical.Count -eq 0) {
    "None found."
} else {
    $global:report.critical | ForEach-Object { "- $_" } | Out-String
})

## Security Issues

$(if ($global:report.security['issues'].Count -eq 0) {
    "None found."
} else {
    $global:report.security['issues'] | ForEach-Object { "- $_" } | Out-String
})

---
*Report generated by inspect-project.ps1*
"@

    $md | Out-File -FilePath $mdFile -Encoding UTF8
    Write-OK "Markdown: $mdFile"
    
    # HTML Report
    $htmlFile = Join-Path $reportDir "inspection-$timestamp.html"
    
    $criticalColor = if ($global:report.critical.Count -eq 0) { "#28a745" } else { "#dc3545" }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Antiplagiat Inspection</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden; }
        header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; }
        header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .content { padding: 40px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center; }
        .metric .value { font-size: 2em; font-weight: bold; color: #667eea; margin: 10px 0; }
        .metric .label { color: #666; font-size: 0.9em; }
        .critical { background: $criticalColor; color: white; padding: 20px; border-radius: 10px; text-align: center; font-size: 1.5em; margin: 20px 0; }
        .section { margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 10px; }
        .section h2 { color: #667eea; margin-bottom: 15px; }
        ul { margin-left: 20px; }
        li { margin: 5px 0; }
        footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Project Inspection Report</h1>
            <p>Antiplagiat AI Platform</p>
            <p>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </header>
        <div class="content">
            <div class="metrics">
                <div class="metric">
                    <div class="label">Lines of Code</div>
                    <div class="value">$($global:report.metrics['total_loc'])</div>
                </div>
                <div class="metric">
                    <div class="label">Project Size</div>
                    <div class="value">$($global:report.metrics['size_mb']) MB</div>
                </div>
                <div class="metric">
                    <div class="label">Total Files</div>
                    <div class="value">$($global:report.metrics['files'])</div>
                </div>
            </div>
            <div class="critical">
                Critical Issues: $($global:report.critical.Count)
            </div>
            <div class="section">
                <h2>Code Quality</h2>
                <p><strong>Backend:</strong> $($global:report.code['python_files']) Python files, $($global:report.code['python_loc']) LOC</p>
                <p><strong>Frontend:</strong> $($global:report.code['ts_files']) TypeScript files, $($global:report.code['ts_loc']) LOC</p>
            </div>
            <div class="section">
                <h2>Issues</h2>
                <p><strong>Critical:</strong> $($global:report.critical.Count)</p>
                <p><strong>Security:</strong> $($global:report.security['issues'].Count)</p>
            </div>
        </div>
        <footer>
            <p>Generated by inspect-project.ps1</p>
        </footer>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $htmlFile -Encoding UTF8
    Write-OK "HTML: $htmlFile"
    
    return $htmlFile
}

# ============================================================================
# MAIN
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host "                PROJECT INSPECTION - ANTIPLAGIAT                         " -ForegroundColor Cyan
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $projectRoot)) {
    Write-ERR "Project not found: $projectRoot"
    exit 1
}

# Run all checks
Test-ProjectStructure
Test-Dependencies
Test-Configurations
Test-CodeQuality
Test-Security
Test-CriticalIssues
Test-GitStatus
Test-Documentation
Get-ProjectMetrics

# Generate reports
$htmlPath = Export-Reports

# Summary
Write-Section "FINAL SUMMARY"
Write-Host ""
Write-INF "Total LOC: $($global:report.metrics['total_loc'])"
Write-INF "Project Size: $($global:report.metrics['size_mb']) MB"
Write-Host ""

if ($global:report.critical.Count -eq 0) {
    Write-OK "No critical issues!"
} else {
    Write-ERR "Critical issues: $($global:report.critical.Count)"
}

if ($global:report.security['issues'].Count -eq 0) {
    Write-OK "No security issues!"
} else {
    Write-WARN "Security issues: $($global:report.security['issues'].Count)"
}

Write-Host ""
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host "  Reports saved in: $reportDir" -ForegroundColor Green
Write-Host "  ========================================================================" -ForegroundColor Cyan
Write-Host ""

if ($OpenHTML) {
    Start-Process $htmlPath
}

Write-Host "  Open HTML report? (Y/N): " -NoNewline -ForegroundColor Cyan
$response = Read-Host
if ($response -eq 'Y' -or $response -eq 'y') {
    Start-Process $htmlPath
}
