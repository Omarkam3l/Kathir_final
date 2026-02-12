# Fix Remaining Flutter Warnings

Write-Host "Fixing remaining warnings..." -ForegroundColor Cyan

# Fix 1: Remove unused import in auth_screen.dart
$file = "lib\features\authentication\presentation\screens\auth_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "import 'package:flutter/foundation\.dart';\s*\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unnecessary import in auth_screen.dart" -ForegroundColor Green
}

# Fix 2: Remove unused import in cart_screen.dart
$file = "lib\features\cart\presentation\screens\cart_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "import '\.\./\.\./\.\./checkout/presentation/screens/checkout_screen\.dart';\s*\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused import in cart_screen.dart" -ForegroundColor Green
}

# Fix 3: Remove unused variables in cart_screen.dart
$file = "lib\features\cart\presentation\screens\cart_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    # Remove unused bgColor variable
    $content = $content -replace "final bgColor = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused variables in cart_screen.dart" -ForegroundColor Green
}

# Fix 4: Remove unused variables in checkout_screen.dart
$file = "lib\features\checkout\presentation\screens\checkout_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    # Remove unused bgColor and surfaceColor variables
    $content = $content -replace "final bgColor = [^\n]+\n", ""
    $content = $content -replace "final surfaceColor = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused variables in checkout_screen.dart" -ForegroundColor Green
}

# Fix 5: Remove unused field in ngo_notifications_screen.dart
$file = "lib\features\ngo_dashboard\presentation\screens\ngo_notifications_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "bool _isCategoriesLoading = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused field in ngo_notifications_screen.dart" -ForegroundColor Green
}

# Fix 6: Remove unused variables in my_orders_screen_new.dart
$file = "lib\features\orders\presentation\screens\my_orders_screen_new.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "final pickupCode = [^\n]+\n", ""
    $content = $content -replace "final orderId = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused variables in my_orders_screen_new.dart" -ForegroundColor Green
}

# Fix 7: Remove unused field in order_tracking_screen.dart
$file = "lib\features\orders\presentation\screens\order_tracking_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "final List<[^>]+> _statusHistory = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused field in order_tracking_screen.dart" -ForegroundColor Green
}

# Fix 8: Remove unused variable in favorites_viewmodel.dart
$file = "lib\features\user_home\presentation\viewmodels\favorites_viewmodel.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "final results = [^\n]+\n", ""
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Fixed unused variable in favorites_viewmodel.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Checking remaining warnings..." -ForegroundColor Green
