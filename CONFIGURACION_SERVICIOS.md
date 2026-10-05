# Configuración de servicios de RDReporta

Actualización: **1 de octubre de 2026**. Esta guía describe la configuración que utiliza el código actual. No implica que los proveedores externos hayan sido validados integralmente.

## Estado de las integraciones

| Servicio | Estado actual |
| --- | --- |
| Correo y sesión | Implementados; recuperación requiere configurar SMTP. |
| Google Sign-In | Cliente y validación del token en la API implementados; validar credenciales y acceso real. |
| Apple Sign-In | Cliente y validación de tokens de Apple en el backend (/api/auth/apple) implementados con verificación JWKS oficial y caché. |
| Firebase/FCM | Emisor con cola persistente y reintentos, registro/renovación de tokens, apertura del reporte y contador de pendientes. La entrega real requiere credenciales del servidor y validación en dispositivo. |
| Google Maps | Mapa Android conectado a clave local; inicialización de Maps en iOS pendiente. |
| Multimedia | Almacenamiento local (desarrollo) y soporte nativo en la nube (AWS S3, Cloudflare R2, Google Cloud Storage, CDN) configurable vía Storage:Provider. |
| Producción | Requiere HTTPS, claves restringidas, firma y comprobaciones finales. |

La aplicación ya contiene los clientes de Google Sign-In, Apple Sign-In,
Firebase Cloud Messaging y Google Maps. Los secretos y archivos emitidos por
los proveedores deben gestionarse según su sensibilidad. Los archivos Firebase del
cliente contienen identificadores públicos que deben tener restricciones por app;
las claves privadas de cuentas de servicio y las credenciales de servidor no se guardan en Git.

## Configuración segura del backend

La API requiere `Jwt:SecretKey` y `ConnectionStrings:DefaultConnection`; ya no existen
valores de respaldo en el código. En este equipo están guardados en .NET User Secrets,
que se carga al ejecutar el perfil de desarrollo:

```powershell
dotnet run --project backend/src/RdReporta.Api --launch-profile http
```

En otros equipos, configurar ambos valores con `dotnet user-secrets set --project
backend/src/RdReporta.Api` o variables de entorno. En producción usar
`Jwt__SecretKey`, `ConnectionStrings__DefaultConnection` y `Cors__AllowedOrigins__0`
con el origen HTTPS exacto del panel. La clave JWT debe ser aleatoria y contener
al menos 32 bytes. La rotación de la clave actual exige iniciar sesión nuevamente.

`docker/.env` conserva la configuración de la base local y está excluido de Git.
Cambiar su contraseña no cambia automáticamente la contraseña de un volumen PostgreSQL
que ya existe; debe rotarse también en la base de datos.

El administrador inicial solo se crea si se proporcionan `SeedAdmin:Email` y
`SeedAdmin:Password` mediante configuración privada. Si ya existe una cuenta creada
con la contraseña anterior, cambiarla antes de un despliegue público.

### Variables de configuración

| Clave en .NET | Variable de entorno equivalente | Uso |
| --- | --- | --- |
| `Jwt:SecretKey` | `Jwt__SecretKey` | Clave JWT obligatoria. |
| `ConnectionStrings:DefaultConnection` | `ConnectionStrings__DefaultConnection` | Conexión PostgreSQL obligatoria. |
| `Cors:AllowedOrigins:0` | `Cors__AllowedOrigins__0` | Origen exacto del panel; añadir índices para otros orígenes. |
| `Authentication:GoogleClientId` | `Authentication__GoogleClientId` | Client ID web aceptado al validar Google. |
| `Authentication:AppleBundleId` | `Authentication__AppleBundleId` | Bundle ID de la app iOS (predeterminado: `com.rdreporta.app`). |
| `Authentication:AppleClientId` | `Authentication__AppleClientId` | Client ID / Services ID adicional de Apple para web/Android. |
| `Storage:Provider` | `Storage__Provider` | `Local` o `S3` (Cloudflare R2, AWS S3, GCS). |
| `Storage:BucketName` | `Storage__BucketName` | Nombre del bucket en S3/R2. |
| `Storage:ServiceUrl` | `Storage__ServiceUrl` | URL del servicio (ej. `https://<accountid>.r2.cloudflarestorage.com` para R2, o `https://storage.googleapis.com` para GCS). |
| `Storage:Region` | `Storage__Region` | Región S3 (ej. `auto` para Cloudflare R2, `us-east-1` para AWS). |
| `Storage:AccessKey` | `Storage__AccessKey` | Access Key ID del proveedor en la nube. |
| `Storage:SecretKey` | `Storage__SecretKey` | Secret Access Key del proveedor en la nube. |
| `Storage:PublicUrlBase` | `Storage__PublicUrlBase` | URL base del CDN o dominio público (ej. `https://cdn.rdreporta.com` o `https://pub-xxxx.r2.dev`). |
| `SeedAdmin:Email` | `SeedAdmin__Email` | Correo del administrador inicial. |
| `SeedAdmin:Password` | `SeedAdmin__Password` | Contraseña inicial privada. |
| `Smtp:Host` | `Smtp__Host` | Servidor SMTP (ej. `smtp.gmail.com`, `smtp.sendgrid.net`). |
| `Smtp:Port` | `Smtp__Port` | Puerto SMTP (predeterminado: 587). |
| `Smtp:From` | `Smtp__From` | Correo remitente (ej. `soporte@rdreporta.com`). |
| `Smtp:Username` | `Smtp__Username` | Usuario o correo de autenticación SMTP. |
| `Smtp:Password` | `Smtp__Password` | Contraseña o App Password del servidor SMTP. |
| `Smtp:EnableSsl` | `Smtp__EnableSsl` | Usar SSL/TLS (predeterminado: true). |

*Nota sobre desarrollo local:* Si `Smtp:Host` no está configurado mientras se ejecuta en modo `Development`, la API genera el código y lo imprime en los logs de la consola para poder probar el flujo completo en la app sin bloquear con error 503.

Los nombres anteriores son configuración del servidor. Los valores `--dart-define` se incorporan al cliente al compilar y no deben contener secretos de servidor. Reiniciar la API después de cambiar su configuración y recompilar Flutter cuando cambien sus definiciones.

## Conexión local: PC, teléfono y emulador

Desde la raíz, mantener Docker Desktop abierto e iniciar la base y la API:

```powershell
docker compose -f .\docker\docker-compose.yml up -d
dotnet run --project .\backend\src\RdReporta.Api --launch-profile http
```

El perfil `http` configura Development y escucha en el puerto 5000. Mantener la terminal de la API abierta; `--no-build` solo funciona si existen binarios compilados.

Para el teléfono actual por USB, en otra terminal:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F reverse tcp:5000 tcp:5000
cd mobile
flutter pub get
flutter run -d R5CR10FC10F --dart-define=API_BASE_URL=http://127.0.0.1:5000/api
```

Para un emulador Android, ejecutar desde `mobile/` con su identificador:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

El valor Android predeterminado del código actual es `http://127.0.0.1:5000/api`; requiere la redirección USB o una redirección equivalente. Para usar Wi-Fi, proporcionar la IP local actual del PC, mantener ambos equipos en una red que permita su comunicación y permitir el puerto de la API en el firewall. No fijar una IP antigua como valor universal.

El panel utiliza `VITE_API_BASE_URL`, con ejemplo en `admin/.env.example`. Es una variable del cliente Vite, no de .NET. Tras cambiarla, reiniciar el servidor de desarrollo o recompilar el panel.

## Firma de Android para producción

Configurar `mobile/android/key.properties` con `storeFile`, `storePassword`, `keyAlias`
y `keyPassword` para la clave de publicación. Este archivo y los keystores están
excluidos de Git. La compilación release ya no usa la clave debug.

La versión release exige una API HTTPS. Ejemplo desde `mobile`:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://TU_DOMINIO/api --obfuscate --split-debug-info=build/symbols
```

Conservar los símbolos junto a la versión publicada. El tráfico HTTP local sigue
habilitado únicamente en el manifiesto debug para desarrollo por USB o red local.

## Firebase y Google Sign-In

1. Crear un proyecto en Firebase Console.
2. Registrar la aplicación Android con `com.rdreporta.app`.
3. Instalar FlutterFire CLI y ejecutar desde `mobile`:

   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Configurar las credenciales OAuth de Google para la aplicación. El flujo actual utiliza `google_sign_in` y envía el ID token directamente a la API; no utiliza Firebase Authentication como sistema de sesión de RDReporta.
5. Añadir las huellas SHA-1 y SHA-256 de las firmas debug y release.
6. Comprobar que el Client ID web de `google-services.json` coincida con
   `Authentication:GoogleClientId` del servidor. La app usa el ID web de este
   proyecto de forma predeterminada. Si se conecta a otro proyecto, indicarlo
   al ejecutar Flutter:

   ```powershell
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=CLIENT_ID_WEB
   ```

Si FlutterFire genera `firebase_options.dart`, tener en cuenta que el código actual no lo importa: inicializa Firebase mediante `Firebase.initializeApp()` sin opciones explícitas y depende de la configuración nativa. Generar un archivo no lo conecta automáticamente a la aplicación. No deben copiarse identificadores inventados.

El servidor valida el token en `POST /api/auth/google` contra `Authentication:GoogleClientId`. Si falta ese valor, devuelve 503; si el token es inválido o vencido, devuelve 401. La salida a Google desde el servidor también debe funcionar. La app tiene un Client ID web predeterminado: al cambiar de proyecto, reemplazarlo mediante `GOOGLE_SERVER_CLIENT_ID` y usar el mismo valor en el servidor.

## Firebase Cloud Messaging

La aplicación solicita permiso y registra el token en
`POST /api/notifications/devices`. Para Android, el archivo
`google-services.json` se genera al configurar Firebase. En iOS se necesita
`GoogleService-Info.plist`, Push Notifications, Background Modes y una clave
APNs cargada en Firebase.

El backend envía las nuevas incidencias a los seguidores mediante Firebase Admin. Guarda cada entrega por dispositivo en `PushDeliveries`, en la misma transacción que la notificación de la bandeja. El proceso en segundo plano consulta la cola cada cinco segundos, reintenta errores transitorios hasta ocho veces y descarta avisos leídos, de más de 24 horas o de publicaciones retiradas. Elimina tokens que FCM identifica como no registrados. Un reinicio excepcional después del envío y antes de confirmar la transacción puede repetir una entrega; el identificador de notificación se usa para agruparla en Android/APNs. Las notificaciones históricas no se reenvían.

Para habilitar el emisor:

1. En Firebase Console → Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada, descargar el JSON de la cuenta de servicio. El selector Node.js/Java/Python/Go solo modifica el ejemplo; el JSON sirve para C#.
2. Guardarlo fuera del repositorio, con acceso limitado al proceso del servidor. Configurar `GOOGLE_APPLICATION_CREDENTIALS` con su ruta absoluta (o usar credenciales predeterminadas de Google en el entorno de despliegue).
3. Configurar `Firebase__ProjectId` con el ID del mismo proyecto que la app y `Firebase__Enabled=true`. Confirmar que la API Firebase Cloud Messaging está habilitada y la cuenta tiene permiso de envío. Reiniciar la API.

Si una política de la organización bloquea la creación de claves, para desarrollo local se puede usar `gcloud auth application-default login` con una cuenta que tenga permiso de envío en el proyecto. No requiere crear una clave privada de cuenta de servicio. En ese caso no establecer `GOOGLE_APPLICATION_CREDENTIALS`: el SDK encuentra las credenciales locales de Google Cloud. Para un servidor desplegado en Google Cloud, usar la identidad asociada al recurso y sus permisos. Véase [ADC para desarrollo local](https://docs.cloud.google.com/docs/authentication/set-up-adc-local-dev-environment).

El arranque crea la tabla e índices de la cola siguiendo el mecanismo existente de `DbInitializer`. El emisor permanece desactivado en `appsettings.json` hasta configurarlo. Los errores de configuración o entrega quedan registrados sin imprimir tokens ni claves.

La app solicita permiso al iniciar sesión, registra el token al entrar/reanudar, escucha su renovación y desvincula el dispositivo al salir. En primer plano muestra un aviso con la acción `Ver`; en segundo plano usa la notificación del sistema. Tocar el aviso abre el reporte y confirma su lectura. Android incluye permiso de notificaciones, icono monocromo y canal de importancia alta.

La campanita consulta `GET /api/notifications/unread-count` al entrar, reanudar, recibir un push y cada 30 segundos mientras la app está activa. Muestra `99+` para cantidades superiores a 99 y oculta el contador cuando no hay pendientes. Funciona sin Firebase. La bandeja carga páginas de 50 y confirma únicamente los IDs cargados mediante `POST /api/notifications/read`; los avisos nuevos o páginas todavía no cargadas permanecen pendientes. Ante fallos de conexión se conserva el último contador confirmado y se permite reintentar la bandeja.

Referencia: [configuración del SDK Admin](https://firebase.google.com/docs/admin/setup) y [recepción e interacción en Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages). La entrega real debe comprobarse con dos cuentas: una sigue a la otra, se publica una incidencia y se comprueba recepción con la app abierta, en segundo plano y cerrada, apertura del reporte, contador y cambio de sesión. iOS requiere además su configuración nativa y APNs; no se valida desde Windows.

Las credenciales privadas del emisor deben permanecer en el servidor; nunca incluir el JSON privado dentro de la aplicación móvil. Si Firebase no se inicializa, el servicio móvil desactiva internamente la sincronización: que la aplicación abra no demuestra que FCM funcione.

## Google Maps

Activar Maps SDK for Android y Maps SDK for iOS en Google Cloud. Restringir cada
clave por aplicación y por API.

En `mobile/android/local.properties` añadir:

```properties
MAPS_API_KEY=clave_android_restringida
```

Para iOS, añadir la clave mediante una configuración privada de Xcode y llamar
a `GMSServices.provideAPIKey` desde `AppDelegate.swift`. La clave de iOS debe
estar restringida al Bundle ID definitivo.

La inicialización de Google Maps está añadida a `AppDelegate.swift` mediante `GMSServices.provideAPIKey`. Android lee `MAPS_API_KEY` desde local.properties y lo pasa al manifiesto. La selección de ubicación de un reporte tocando el mapa está implementada mediante `LocationPickerScreen`. La clave en Google Cloud debe tener habilitado el Maps SDK for iOS.

## Apple Sign-In

Requiere una cuenta de Apple Developer, un App ID con la capacidad **Sign in
with Apple**, un Service ID para Android/web y la asociación correspondiente en
el servidor. Xcode debe tener añadida la capacidad
`com.apple.developer.applesignin`.

**Endpoint `/api/auth/apple`:** El backend ya valida la firma criptográfica RSA del token contra las claves públicas oficiales de Apple (`https://appleid.apple.com/auth/keys`), comprueba emisor (`https://appleid.apple.com`), audiencia (`Authentication:AppleBundleId`, predeterminado `com.rdreporta.app`), vigencia temporal y estado del correo electrónico verificado, registrando o iniciando la sesión del usuario de forma automática.

## Recuperación de contraseña por SMTP

El servidor utiliza estas claves o sus variables equivalentes:

| Clave | Variable de entorno |
| --- | --- |
| `Smtp:Host` | `Smtp__Host` |
| `Smtp:Port` | `Smtp__Port` |
| `Smtp:From` | `Smtp__From` |
| `Smtp:EnableSsl` | `Smtp__EnableSsl` |
| `Smtp:Username` | `Smtp__Username` |
| `Smtp:Password` | `Smtp__Password` |

El puerto predeterminado es 587 y EnableSsl es true. Usar valores compatibles con el proveedor. Si faltan Host o From, `POST /api/auth/forgot-password` devuelve 503. El código dura 20 minutos y se consume al cambiar la contraseña mediante `/api/auth/reset-password`.

La respuesta pública no revela si una cuenta existe. Un error de entrega SMTP se registra en el servidor y puede conservar la misma respuesta pública: comprobar la recepción del correo, no solo el código HTTP. Persistir las claves de Data Protection en la carpeta `.data-protection-keys` del ContentRoot de la API; no eliminarlas ni perderlas al recrear el despliegue.

El cambio de contraseña revoca el refresh token. Los JWT de acceso ya emitidos conservan su vigencia hasta que expiren.

## Almacenamiento multimedia

Por defecto, la API utiliza `LocalStorageService` (entorno local de desarrollo), guardando en `backend/src/RdReporta.Api/wwwroot/uploads/`.

Para servidores reales y producción, la API cuenta con soporte nativo S3-compatible (`S3StorageService`) que se activa configurando `Storage:Provider=S3` (o `R2`, `Cloud`). Es compatible con:
- **Cloudflare R2:** `Storage:ServiceUrl=https://<account_id>.r2.cloudflarestorage.com`, `Storage:Region=auto`.
- **AWS S3:** `Storage:Region=us-east-1` (o la región correspondiente).
- **Google Cloud Storage:** Mediante la interoperabilidad S3 (`https://storage.googleapis.com` con claves HMAC).
- **CDN / Dominio personalizado:** Configurando `Storage:PublicUrlBase` (ej. `https://cdn.rdreporta.com` o `https://pub-xxxx.r2.dev`) para servir los medios directamente a través de una red de distribución de contenidos.

Tanto las imágenes individuales con sanitización de metadatos como los videos subidos directamente o por bloques se guardan en el proveedor configurado. Los videos se limitan a 3 minutos y 150 MiB; ambos límites se validan antes de conservar el archivo definitivo.

## Sesión persistente

Los flujos que generan una sesión válida guardan los tokens en almacenamiento
seguro (incluyendo Google y Apple Sign-In). La sesión se recupera al abrir la app y los tokens de acceso se renuevan
automáticamente. Los refresh tokens rotan en cada renovación, se guardan mediante
SHA-256 y no tienen caducidad automática por inactividad. Cerrar sesión elimina
las credenciales locales y revoca la renovación en la API cuando hay conexión.
La recuperación de contraseña y una revocación del servidor pueden invalidar
la sesión. Una caída de red conserva la sesión guardada.

## Contadores de vistas en tiempo real

La app comparte el contador de cada reporte entre tarjetas y detalle. La API
envía las nuevas vistas mediante SSE en `/api/posts/views/live?ids=...`, con
una instantánea al conectar y reconexión automática al recuperar la conexión
o volver al primer plano. Esta suscripción solo lee contadores; no registra
visualizaciones adicionales.

El proxy de producción debe permitir conexiones SSE persistentes y desactivar
su buffering para esa ruta. El distribuidor de eventos actual funciona en una
instancia de la API; antes de desplegar varias réplicas, conectar un distribuidor
compartido de eventos, por ejemplo Redis.

## Validación y pendientes de publicación

Esta actualización es documental: no configura credenciales ni ejecuta pruebas con proveedores reales. Comprobar por separado acceso Google, recuperación SMTP, mapas Android/iOS y entrega push una vez completadas las integraciones pendientes.

El panel administrativo web (admin/) ha sido corregido en sus definiciones de TypeScript y compila exitosamente (`npm run build`). Consultar el [README](README.md), el [resumen técnico](RESUMEN_PROYECTO.md) y la [auditoría](AUDITORIA_Y_SEGURIDAD.md) para el estado comprobado. Los términos y la política de privacidad siguen identificados como versión de desarrollo; los plazos de conservación deben definirse antes del lanzamiento.
