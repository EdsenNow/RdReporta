# Integración de interfaz y flujos

Actualización: 28 de septiembre de 2026.

La prioridad acordada es terminar la interfaz y los flujos con el backend existente. Los servicios externos quedan para una etapa posterior.

## Conectado en el código

- Panel: inicio de sesión de administradores y moderadores, renovación de sesión, cierre de sesión, métricas globales, búsqueda, filtros, paginación y detalle con fotos.
- Publicaciones: cambios de estado desde el panel, visibles en las consultas públicas. El historial del autor incluye también publicaciones retiradas y archivadas.
- Moderación: resolución de denuncias con notas, descarte y ocultación. Se rechaza resolver de nuevo una denuncia ya atendida.
- Categorías: creación y edición para administradores; consulta para moderadores.
- Móvil: recordar sesión funciona; ambos tokens se guardan y la renovación concurrente se comparte. Un fallo de conexión no se presenta como una lista vacía.
- Perfil: edición de provincia y municipio, historial paginado, fecha de ingreso y confirmaciones recibidas con los nombres reales del contrato API.
- Reportes: fotos conectadas a la subida existente, reintento sin repetir fotos ya cargadas y detención si falla una foto. Las URLs se conservan relativas para funcionar entre dispositivos.
- Ubicación: ya no se publica una coordenada predeterminada; el usuario usa GPS o introduce las coordenadas. El municipio se introduce por separado. Cerca de mí solicita ubicación explícitamente.
- Registro y creación: catálogo compartido de las 31 provincias y el Distrito Nacional, tomado de la semilla geográfica existente.
- Interacciones: reacción Importante, copia del reporte, protección de acciones para invitados y motivos de denuncia compatibles con el servidor.
- Calidad visual: estados de carga/error/reintento, formularios adaptables, correcciones de desbordamiento en acceso y panel adaptable a pantallas pequeñas.
- Revisión móvil adicional: inicio, radar, populares, perfil, creación, detalle y navegación probados con nombres largos y contadores grandes. Tarjetas, botones y estadísticas se ajustan al ancho; las opciones de perfil muestran correctamente sus respuestas táctiles.
- Panel: las denuncias permiten inspeccionar la publicación completa antes de resolver; los diálogos gestionan foco, navegación por teclado y cierre con Escape.
- Auditoría: el escaneo NuGet comprueba vulnerabilidades del resultado JSON y no aprueba una ejecución fallida.

## Preparado, sin activar

La recuperación incluye formulario para solicitar un código y cambiar la contraseña, endpoints, caducidad de 20 minutos y consumo único del código. Sin SMTP responde que todavía no está disponible. Para configurarlo más adelante se usan `Smtp__Host`, `Smtp__Port`, `Smtp__From`, `Smtp__EnableSsl`, `Smtp__Username` y `Smtp__Password` como variables de entorno. En un despliegue se deben persistir y proteger las claves de ASP.NET Data Protection. El cambio revoca el refresh token; los JWT ya emitidos conservan su vigencia actual.

Google y Apple conservan su presentación visual, pero informan que estarán disponibles próximamente y no generan una sesión ficticia. El radar actual sigue siendo esquemático y así se identifica en pantalla.

## Pendiente por decisión de prioridad

- Proveedor de mapas real y selección de ubicación directamente sobre el mapa.
- Firebase/FCM y notificaciones; no se han registrado dispositivos ni conectado cuentas externas.
- Acceso real con Google/Apple y entrega SMTP.
- Almacenamiento multimedia remoto, tratamiento de metadatos EXIF, despliegue, credenciales de producción y firma de aplicaciones.
- Verificación completa con PostgreSQL/PostGIS en ejecución y dispositivos Android/iOS: cámara, permisos GPS y subida real.

## Configuración local

El panel permite `VITE_API_BASE_URL` (ver `admin/.env.example`). La aplicación permite `flutter run --dart-define=API_BASE_URL=http://IP_DEL_EQUIPO:5000/api`. Por defecto usa `10.0.2.2` en el emulador Android y `localhost` en otras plataformas. La API requiere .NET 10 y la base PostgreSQL/PostGIS del proyecto. La configuración de HTTP local en dispositivos y los permisos de red deben revisarse al probar cada plataforma; producción debe usar HTTPS.

No se añadieron cambios de esquema de base de datos. Se mantiene el almacenamiento local actual. Compilar y pasar pruebas de interfaz/cliente no sustituye la prueba integral con la base de datos y los servicios activos.

## Verificación reproducible

- `dotnet build backend/src/RdReporta.Api --no-restore`: compilación de la API.
- Desde `mobile`: `flutter analyze` y `flutter test`. Pruebas de tokens, renovación concurrente, errores, perfil y pantallas de acceso a dos tamaños.
- Desde `admin`: `npm run build` y `npm run lint`.
- `node scripts/check_admin.cjs`: navegación real en Chrome/Edge con respuestas API controladas. Comprueba acceso, búsqueda, cambios de estado, moderación, creación de categorías y cierre de sesión. Guarda capturas en `artifacts/admin-check/`. No certifica el funcionamiento de PostgreSQL ni usa cuentas reales.
