param([string]$BaseUrl = 'http://127.0.0.1:5001/api')
$ErrorActionPreference = 'Stop'
if ($BaseUrl -notmatch '^http://127\.0\.0\.1:\d+/api$') {
    throw 'Esta prueba crea cuentas temporales y solo puede ejecutarse contra la API local.'
}
$auditUsername = 'audit_' + [Guid]::NewGuid().ToString('N')
$auditEmail = "$auditUsername@example.invalid"
$auditPassword = 'Audit9!' + [Guid]::NewGuid().ToString('N')
$auditUserId = $null
$httpClient = [System.Net.Http.HttpClient]::new()

function Send-Request([string]$method, [string]$path, $payload = $null, [string]$token = '') {
    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($method), "$BaseUrl$path")
    try {
        if ($null -ne $payload) {
            $request.Content = [System.Net.Http.StringContent]::new(
                ($payload | ConvertTo-Json -Depth 10 -Compress), [System.Text.Encoding]::UTF8, 'application/json')
        }
        if ($token) { $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token) }
        $response = $httpClient.SendAsync($request).GetAwaiter().GetResult()
        try {
            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            return @{ Status = [int]$response.StatusCode; Body = $(if ($body) { $body | ConvertFrom-Json }); Headers = $response.Headers.ToString() }
        } finally { $response.Dispose() }
    } finally { $request.Dispose() }
}
function Assert-Status($response, [int]$status, [string]$label) {
    if ($response.Status -ne $status) { throw "$label : se esperaba $status y se recibió $($response.Status)." }
    Write-Host "PASS: $label"
}

try {
    $categories = Send-Request GET '/categories'
    Assert-Status $categories 200 'Lectura pública de categorías'
    if ($categories.Headers -notmatch 'X-Content-Type-Options: nosniff') { throw 'Faltan cabeceras defensivas.' }
    Assert-Status (Send-Request GET '/users/me') 401 'Perfil privado exige autenticación'
    Assert-Status (Send-Request POST '/auth/register' @{ username=$auditUsername; email=$auditEmail; password='weak' }) 400 'Contraseña débil rechazada'
    $registered = Send-Request POST '/auth/register' @{ username=$auditUsername; email=$auditEmail; password=$auditPassword }
    Assert-Status $registered 200 'Registro válido'
    $session = $registered.Body.data
    $auditUserId = [Guid]::Parse($session.userId)
    Assert-Status (Send-Request GET '/management/stats' $null $session.accessToken) 403 'Ciudadano no accede a administración'
    Assert-Status (Send-Request PATCH '/users/me' @{avatarUrl='/uploads/../image.jpg'} $session.accessToken) 400 'Avatar con ruta manipulada rechazado'
    $post = @{
        categoryId=$categories.Body.data[0].id; title='Security audit'; description='Temporary validation'
        province='Distrito Nacional'; municipality='Santo Domingo'
        imageUrls=@("/uploads/$([Guid]::NewGuid().ToString('N'))_$([Guid]::NewGuid().ToString('N')).jpg")
    }
    Assert-Status (Send-Request POST '/posts' $post $session.accessToken) 400 'Medio de otro propietario rechazado'
    $ticket = @{accessToken=$session.accessToken; refreshToken=$session.refreshToken}
    $renewed = Send-Request POST '/auth/refresh' $ticket
    Assert-Status $renewed 200 'Refresh válido rota la sesión'
    Assert-Status (Send-Request POST '/auth/refresh' $ticket) 400 'Refresh anterior no se puede reutilizar'
    $nextSession = $renewed.Body.data
    Assert-Status (Send-Request POST '/auth/logout' $null $nextSession.accessToken) 200 'Cierre de sesión'
    Assert-Status (Send-Request POST '/auth/refresh' @{accessToken=$nextSession.accessToken; refreshToken=$nextSession.refreshToken}) 400 'Logout revoca refresh'
} finally {
    $httpClient.Dispose()
    if ($auditUserId) {
        # Delete only the generated account, guarded by both its ID and unique email.
        $cleanupSql = 'DELETE FROM "Users" WHERE "Id" = ''' + $auditUserId.ToString() + ''' AND "Email" = ''' + $auditEmail + ''';'
        & docker exec rdreporta_postgres psql -U postgres -d rdreporta_db -v ON_ERROR_STOP=1 -c $cleanupSql
        if ($LASTEXITCODE -ne 0) { throw "No se pudo limpiar la cuenta temporal $auditUsername." }
    }
}
exit 0
