# RDReporta 🇩🇴

Aplicación de reportes ciudadanos geolocalizados en República Dominicana. Permite publicar incidencias con fotos y videos, consultar reportes cercanos, reaccionar, seguir usuarios y denunciar contenido. Incluye un panel de administración y moderación. No incorpora mensajes privados ni comentarios en las publicaciones.

Actualizado: **1 de octubre de 2026**. Proyecto en desarrollo; las integraciones externas y el despliegue de producción tienen pendientes.

## Funciones implementadas

- Registro e inicio de sesión por correo, Google y Apple, con sesión persistente y tokens almacenados de forma segura.
- Reportes con categoría, descripción, fotos, video y ubicación por GPS o coordenadas. Los videos admiten hasta 3 minutos y 150 MiB, con validación en la app y la API; la subida se realiza por bloques.
- Inicio, reportes cercanos, recientes, populares e historial del autor.
- Carrusel horizontal de fotos y videos, reacciones, perfiles y seguimiento de usuarios.
- Google Maps con marcadores verdes para reportes propios y rojos para los de otros usuarios.
- Contadores de vistas compartidos y actualización mediante SSE desde la API.
- Temas claro y oscuro Rosé Pine, términos y política de privacidad accesibles desde el ingreso.
- Panel con gestión de publicaciones, denuncias, categorías, usuarios y métricas.

La existencia del código no certifica el funcionamiento de un proveedor externo ni la estabilidad en todos los dispositivos. Consulta el estado siguiente antes de preparar un lanzamiento.

## Estado de integraciones

| Servicio | Estado |
| --- | --- |
| Google Sign-In | Cliente móvil y validación del token en la API implementados. Requiere configuración del proveedor y validación integral. |
| Apple Sign-In | Cliente móvil preparado; falta el endpoint `/api/auth/apple` y su validación en el servidor. |
| Firebase/FCM | Inicialización y registro de tokens de dispositivos implementados. Envío remoto push pendiente. |
| Google Maps | Mapa real implementado; requiere claves restringidas por plataforma. Seleccionar la ubicación de un nuevo reporte tocando el mapa sigue pendiente. |
| Recuperación de contraseña | Formularios y endpoints implementados; la entrega de correos requiere SMTP configurado. |
| Multimedia | Almacenamiento local en la API. Las imágenes se procesan para retirar metadatos. Almacenamiento remoto pendiente. |
| Producción | Pendientes despliegue HTTPS, configuración final, firma y validación con proveedores/dispositivos reales. |
| Panel administrativo | Tiene errores de TypeScript pendientes en `ThemeSelector.tsx` e importaciones de tipos; la última compilación no se completó. |

## Estructura

```text
RDReporta/
├── mobile/       # Flutter; Android, iOS y proyectos de otras plataformas
├── backend/      # API ASP.NET Core, aplicación, dominio e infraestructura
├── admin/        # React + TypeScript + Vite
├── database/     # Scripts PostGIS y semillas de referencia
├── docker/       # PostgreSQL/PostGIS y configuración local
├── scripts/      # Herramientas de revisión y auditoría
├── docs/         # Documentación técnica e inventario de limpieza
└── maintenance/  # Información del respaldo local de archivos retirados
```

La API usa **.NET 10**, Entity Framework Core, PostgreSQL/PostGIS y autenticación JWT. Los archivos multimedia se guardan en `backend/src/RdReporta.Api/wwwroot/uploads/`. El volumen Docker `rdreporta_pgdata` conserva la base de datos.

## Requisitos

- .NET SDK **10**.
- Flutter SDK compatible con `mobile/pubspec.yaml`, Android SDK y un emulador o teléfono con depuración USB.
- Docker Desktop con Docker Compose.
- Para el panel, Node.js **20.19+ de la rama 20 o 22.12+**; es el requisito de la versión instalada de Vite.
- Para compilar iOS, macOS con Xcode y la configuración correspondiente de Apple.

## Ejecutar en desarrollo

Los primeros dos pasos se ejecutan desde la raíz del repositorio en PowerShell.

### 1. Base de datos

En la primera configuración, copia `docker/.env.example` a `docker/.env` y reemplaza la contraseña de ejemplo. Mantén Docker Desktop abierto.

```powershell
docker compose -f .\docker\docker-compose.yml up -d
```

PostgreSQL queda disponible en el puerto 5432. Cambiar la contraseña del archivo `.env` no cambia la de una base ya creada: consulta la guía de configuración.

### 2. API

Configura `Jwt:SecretKey` y `ConnectionStrings:DefaultConnection` mediante .NET User Secrets o variables de entorno. No hay credenciales de respaldo. El proceso se detalla en [Configuración de servicios](CONFIGURACION_SERVICIOS.md).

```powershell
dotnet run --project .\backend\src\RdReporta.Api --launch-profile http
```

Mantén esa terminal abierta. El perfil de desarrollo escucha en el puerto 5000. Puedes consultar `/api/categories` para comprobar la conexión. Para ejecutar con `--no-build`, debes haber compilado antes.

### 3. Teléfono Android por USB

En otra terminal, desde la raíz, instala las dependencias y ejecuta Flutter. Sustituye el identificador por el que muestre `adb devices` si utilizas otro teléfono.

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F reverse tcp:5000 tcp:5000
cd mobile
flutter pub get
flutter run -d R5CR10FC10F --dart-define=API_BASE_URL=http://127.0.0.1:5000/api
```

El teléfono necesita el cable USB, Docker y la API activos para acceder al servidor local. Repite `adb reverse` si desconectas el dispositivo o se pierde la redirección.

Para abrir la aplicación ya instalada sin volver a compilar:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F reverse tcp:5000 tcp:5000
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F shell am start -n com.rdreporta.app/.MainActivity
```

### 4. Emulador Android

Enciéndelo y ejecuta desde `mobile/`, usando el identificador que muestre `flutter devices`:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

Define la URL explícitamente: el valor Android predeterminado actual es `http://127.0.0.1:5000/api`, adecuado para la redirección USB.

### 5. Panel administrativo

Desde `admin/`:

```powershell
npm ci
npm run dev
```

La variable `VITE_API_BASE_URL` configura la API; consulta `admin/.env.example`. La cuenta administrativa inicial requiere `SeedAdmin:Email` y `SeedAdmin:Password` mediante configuración privada. No existe una contraseña predeterminada para nuevas instalaciones.

## Comprobaciones y compilación

Estos son comandos disponibles para ejecutarlos cuando corresponda; no indican que todos hayan pasado en el estado actual.

| Ubicación | Comando | Propósito |
| --- | --- | --- |
| Raíz | `dotnet build backend/src/RdReporta.Api` | Compilar la API. |
| `mobile/` | `flutter analyze` | Analizar el código móvil. |
| `mobile/` | `flutter test` | Ejecutar las pruebas móviles. |
| `admin/` | `npm run build` | Compilar el panel; actualmente hay errores pendientes. |
| `admin/` | `npm run lint` | Revisar el código del panel. |

La limpieza más reciente dejó `flutter analyze --no-pub` sin problemas. Consulta [Auditoría y seguridad](AUDITORIA_Y_SEGURIDAD.md) para evidencias, alcance y validaciones pendientes. La configuración de firma Android y la API HTTPS de release están en la guía de servicios.

## Documentación

- [Configuración de servicios, credenciales y producción](CONFIGURACION_SERVICIOS.md).
- [Auditoría y seguridad](AUDITORIA_Y_SEGURIDAD.md).
- [Archivos retirados y candidatos a limpieza](docs/AUDITORIA_ARCHIVOS_SIN_USO.md).
- [Respaldo local de mantenimiento](maintenance/README.md).
- [Requisitos funcionales](docs/requirements/functional_requirements.md).
- [Arquitectura](docs/architecture/system_overview.md).
- [Modelo de datos](docs/database/data_model.md).
- [Especificación de API](docs/api/endpoints_spec.md).

`INTEGRACIONES_Y_PENDIENTES.md` conserva una revisión anterior del 28 de septiembre: sus referencias a confirmaciones y servicios sin conectar están desactualizadas. Para el estado resumido actual, utiliza este README; para configurar cada proveedor, utiliza la guía de servicios.
