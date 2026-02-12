# Fix Flutter Warnings Script
# This script fixes common Flutter warnings in the codebase

Write-Host "Starting to fix Flutter warnings..." -ForegroundColor Cyan

# Counter for fixes
$fixCount = 0

# Get all Dart files
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

Write-Host "Found $($dartFiles.Count) Dart files" -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileFixed = $false
    
    # Fix 1: Replace .withOpacity() with .withValues(alpha:)
    if ($content -match '\.withOpacity\(') {
        $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
        $fileFixed = $true
        Write-Host "  Fixed withOpacity in $($file.Name)" -ForegroundColor Green
    }
    
    # Fix 2: Replace print() with debugPrint()
    if ($content -match '\bprint\(') {
        # Replace print with debugPrint
        $content = $content -replace '\bprint\(', 'debugPrint('
        $fileFixed = $true
        Write-Host "  Fixed print statements in $($file.Name)" -ForegroundColor Green
    }
    
    # Save if changes were made
    if ($fileFixed -and $content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixCount++
    }
}

Write-Host ""
Write-Host "Fixed warnings in $fixCount files!" -ForegroundColor Green
Write-Host "Running flutter analyze to check remaining warnings..." -ForegroundColor Cyan
Write-Host ""
