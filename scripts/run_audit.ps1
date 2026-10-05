# RDReporta: comprobaciones locales reproducibles de calidad y seguridad.
param([string]$ApiBaseUrl = '')
$ErrorActionPreference = "Continue"
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$passed = 0
$failed = 0
$total = 11
if ($ApiBaseUrl) { $total++ }

function Complete-Check([bool]$ok, [string]$success, [string]$failure) {
    if ($ok) {
        Write-Host "  OK: $success" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  ERROR: $failure" -ForegroundColor Red
        $script:failed++
    }
}

$flutter = "flutter"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\src\flutter\bin\flutter.bat") { $flutter = "C:\src\flutter\bin\flutter.bat" }
}

Write-Host "RDReporta - auditoría local ($total comprobaciones)" -ForegroundColor Cyan

Write-Host "[1/$total] Compilación del backend"
dotnet build "backend\src\RdReporta.Api\RdReporta.Api.csproj" --nologo -v q -warnaserror
Complete-Check ($LASTEXITCODE -eq 0) "Backend sin errores ni advertencias." "La compilación del backend falló."

Write-Host "[2/$total] Dependencias NuGet vulnerables"
$nugetJson = dotnet list "backend\RdReporta.slnx" package --vulnerable --include-transitive --format json --no-restore
$nugetExit = $LASTEXITCODE
$nugetSafe = $false
try {
    $audit = ($nugetJson -join "`n") | ConvertFrom-Json -ErrorAction Stop
    if (@($audit.projects).Count -eq 0) { throw 'NuGet no devolvió proyectos.' }
    $vulnerable = @($audit.projects | ForEach-Object { $_.frameworks } | ForEach-Object {
        @($_.topLevelPackages) + @($_.transitivePackages)
    } | Where-Object { $_.vulnerabilities.Count -gt 0 })
    $scanErrors = @($audit.logs | Where-Object { $_.level -in @('error', 'warning') })
    $nugetSafe = $nugetExit -eq 0 -and $vulnerable.Count -eq 0 -and $scanErrors.Count -eq 0
} catch { $nugetSafe = $false }
Complete-Check $nugetSafe "NuGet no informó vulnerabilidades conocidas." "NuGet no pudo comprobarse o informó paquetes vulnerables."

Write-Host "[3/$total] Integridad y aislamiento de cargas de video"
dotnet run --project "backend\tests\VideoUploadChecks\VideoUploadChecks.csproj" --no-restore
Complete-Check ($LASTEXITCODE -eq 0) "Carga por bloques conserva contenido, reintentos y propietario." "Falló la comprobación de cargas de video."

Write-Host "[4/$total] Eliminación de metadatos de imágenes"
dotnet run --project "backend\tests\ImageSecurityChecks\ImageSecurityChecks.csproj" --no-restore
Complete-Check ($LASTEXITCODE -eq 0) "Imágenes reales conservan orientación y eliminan metadatos; archivos dañados y rutas ajenas se rechazan." "Falló la comprobación de seguridad de imágenes."

Write-Host "[5/$total] Pruebas Flutter"
Push-Location "mobile"
& $flutter test --no-pub
$flutterTests = $LASTEXITCODE
Pop-Location
Complete-Check ($flutterTests -eq 0) "Pruebas Flutter aprobadas." "Hay pruebas Flutter fallidas."

Write-Host "[6/$total] Análisis estático Flutter"
Push-Location "mobile"
& $flutter analyze --no-pub
$flutterAnalyze = $LASTEXITCODE
Pop-Location
Complete-Check ($flutterAnalyze -eq 0) "Flutter analyze sin hallazgos." "Flutter analyze informó problemas."

Write-Host "[7/$total] Linter del panel administrativo"
Push-Location "admin"
npm run lint --silent
$adminLint = $LASTEXITCODE
Pop-Location
Complete-Check ($adminLint -eq 0) "Linter del panel aprobado." "El linter del panel informó problemas."

Write-Host "[8/$total] Compilación del panel administrativo"
Push-Location "admin"
npm run build --silent
$adminBuild = $LASTEXITCODE
Pop-Location
Complete-Check ($adminBuild -eq 0) "Panel administrativo compilado." "Falló la compilación del panel."

Write-Host "[9/$total] Auditoría npm de severidad alta o crítica"
Push-Location "admin"
npm audit --audit-level=high
$npmAudit = $LASTEXITCODE
Pop-Location
Complete-Check ($npmAudit -eq 0) "npm no informó vulnerabilidades altas o críticas." "npm informó vulnerabilidades altas/críticas o no pudo completar el análisis."

Write-Host "[10/$total] Secretos y credenciales predeterminadas en archivos rastreados"
$secretHits = @(git grep -n -E 'RDReporta_UltraSecure|postgres_dev_password|Admin123!' -- ':!AUDITORIA_Y_SEGURIDAD.md' ':!CONFIGURACION_SERVICIOS.md' ':!scripts/run_audit.ps1' 2>$null)
$secretScanExit = $LASTEXITCODE
Complete-Check ($secretHits.Count -eq 0 -and $secretScanExit -eq 1) "No hay secretos de desarrollo conocidos en el código rastreado." "La búsqueda falló o encontró credenciales predeterminadas."

Write-Host "[11/$total] Configuración de seguridad Android y API"
$program = Get-Content "backend\src\RdReporta.Api\Program.cs" -Raw
$gradle = Get-Content "mobile\android\app\build.gradle.kts" -Raw
$manifest = Get-Content "mobile\android\app\src\main\AndroidManifest.xml" -Raw
$configSafe = $program -notmatch 'AllowAnyOrigin|DevelopmentOnly_ChangeInProduction' -and
    $gradle -notmatch 'signingConfigs\.getByName\("debug"\)' -and
    $manifest -match 'allowBackup="false"' -and $manifest -match 'usesCleartextTraffic="false"'
Complete-Check $configSafe "CORS, firma release, copias y tráfico claro tienen políticas explícitas." "La configuración conserva un patrón inseguro."

if ($ApiBaseUrl) {
    Write-Host "[12/$total] Seguridad HTTP contra la API local y PostgreSQL"
    & (Join-Path $PSScriptRoot 'check_api_security.ps1') -BaseUrl $ApiBaseUrl
    Complete-Check ($LASTEXITCODE -eq 0) "Permisos, contraseñas, medios, rotación y logout verificados por HTTP." "Falló la comprobación HTTP."
}

Write-Host ""
Write-Host "Resultado: $passed/$total aprobadas; $failed fallidas." -ForegroundColor Cyan
if ($failed -gt 0) {
    Write-Host "Estado: requiere atención. Una comprobación aprobada no equivale por sí sola a seguridad total." -ForegroundColor Yellow
    exit 1
}

Write-Host "Estado: controles automatizados aprobados. Mantener revisión manual, pruebas de abuso y monitoreo." -ForegroundColor Green
exit 0
