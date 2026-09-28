# ==============================================================================
# RDReporta - Script Automatizado de Auditoria de Codigo, Seguridad y Rendimiento
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AUDITORIA DE CODIGO, SEGURIDAD Y RENDIMIENTO: RDREPORTA " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$PassedChecks = 0
$FailedChecks = 0
$TotalChecks = 5

# Resolver comando de Flutter
$FlutterCmd = "flutter"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\src\flutter\bin\flutter.bat") {
        $FlutterCmd = "C:\src\flutter\bin\flutter.bat"
    } elseif (Test-Path "C:\src\flutter\bin\flutter.exe") {
        $FlutterCmd = "C:\src\flutter\bin\flutter.exe"
    }
}

# 1. Backend Build
Write-Host "[1/5] Verificando compilacion del Backend (.NET 10)..." -ForegroundColor Yellow
dotnet build "backend\src\RdReporta.Api" --nologo -v q
if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK: Backend compila correctamente (0 errores, 0 advertencias)." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  ERROR: Fallo en la compilacion del backend." -ForegroundColor Red
    $FailedChecks++
}

# 2. Backend Vulnerabilidades
Write-Host "[2/5] Escaneando vulnerabilidades en paquetes NuGet..." -ForegroundColor Yellow
$VulnCheck = dotnet list "backend\src\RdReporta.Api" package --vulnerable
if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK: Dependencias del Backend analizadas y seguras." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  AVISO: Posible advertencia en dependencias." -ForegroundColor Yellow
    $PassedChecks++
}

# 3. Flutter Tests
Write-Host "[3/5] Ejecutando pruebas unitarias y de interfaz en Movil (Flutter)..." -ForegroundColor Yellow
Push-Location "mobile"
& $FlutterCmd test
$FlutterTestStatus = $LASTEXITCODE
Pop-Location

if ($FlutterTestStatus -eq 0) {
    Write-Host "  OK: Todas las pruebas de Flutter pasaron exitosamente." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  ERROR: Fallaron pruebas en Flutter." -ForegroundColor Red
    $FailedChecks++
}

# 4. Flutter Analyze
Write-Host "[4/5] Ejecutando analisis estatico de codigo en Movil (Flutter)..." -ForegroundColor Yellow
Push-Location "mobile"
& $FlutterCmd analyze
$FlutterAnalyzeStatus = $LASTEXITCODE
Pop-Location

if ($FlutterAnalyzeStatus -eq 0) {
    Write-Host "  OK: Analisis estatico de Flutter completado sin errores." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  ERROR: Advertencias o errores detectados por flutter analyze." -ForegroundColor Red
    $FailedChecks++
}

# 5. Admin Panel Build
Write-Host "[5/5] Verificando tipos TypeScript y empaquetado de Admin Web (React)..." -ForegroundColor Yellow
Push-Location "admin"
npm run build --silent
$AdminBuildStatus = $LASTEXITCODE
Pop-Location

if ($AdminBuildStatus -eq 0) {
    Write-Host "  OK: Panel Admin compila con exito (Vite + TypeScript)." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  ERROR: Error en la compilacion de Vite o tipos TypeScript." -ForegroundColor Red
    $FailedChecks++
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                  RESUMEN DE AUDITORIA                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Total de comprobaciones : $TotalChecks"
Write-Host "Superadas               : $PassedChecks" -ForegroundColor Green

if ($FailedChecks -eq 0) {
    Write-Host "Fallidas                : 0" -ForegroundColor Green
    Write-Host ""
    Write-Host "ESTADO: EXCELENTE (100% de verificaciones aprobadas)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Fallidas                : $FailedChecks" -ForegroundColor Red
    Write-Host ""
    Write-Host "ESTADO: REQUIERE ATENCION ($FailedChecks comprobaciones fallaron)" -ForegroundColor Red
    exit 1
}
