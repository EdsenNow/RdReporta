# Resumen técnico y estado del proyecto

**Proyecto:** RDReporta

**Actualización:** 1 de octubre de 2026

**Propósito:** describir la arquitectura, las tecnologías realmente presentes y los pendientes. Este documento distingue implementación de validación; no certifica que todas las funciones estén listas para producción.

## 1. Producto

RDReporta permite publicar y consultar incidencias ciudadanas geolocalizadas en República Dominicana. Los reportes incluyen categoría, título, descripción, fotografías, video y dirección.

La interacción incluye reacciones, visualizaciones, seguimiento de usuarios y denuncias para moderación. No hay mensajes privados ni comentarios abiertos. Las confirmaciones ciudadanas fueron retiradas.

La interfaz utiliza Rosé Pine para modo oscuro y Rosé Pine Dawn para modo claro. La selección de esta paleta no demuestra por sí sola cumplimiento WCAG: el contraste, los tamaños de texto y la interacción deben comprobarse en cada pantalla.

## 2. Arquitectura

| Área | Ubicación | Responsabilidad |
| --- | --- | --- |
| Aplicación móvil | mobile/ | Interfaz Flutter, autenticación, ubicación, multimedia y comunicación con la API. |
| API | backend/src/RdReporta.Api/ | Controladores, configuración, autenticación HTTP y publicación de eventos de vistas. |
| Aplicación | backend/src/RdReporta.Application/ | Servicios, casos de uso, contratos y DTO. |
| Dominio | backend/src/RdReporta.Domain/ | Entidades y enumeraciones. |
| Infraestructura | backend/src/RdReporta.Infrastructure/ | Persistencia EF Core, seguridad y almacenamiento local. |
| Panel | admin/ | Administración y moderación en React. |
| Base de datos | database/, docker/ | Scripts, semillas de referencia y PostgreSQL/PostGIS local. |
| Revisión | scripts/, backend/tests/, mobile/test/ | Herramientas y pruebas disponibles. |
| Documentación | docs/ | Especificaciones e inventario de limpieza. |

La API y ambos clientes se comunican mediante HTTP en desarrollo local y deben utilizar HTTPS en producción. La estructura del backend separa responsabilidades, pero no implica que todos los servicios sean completamente independientes de EF Core.

## 3. Aplicación móvil

### Tecnologías declaradas

Los valores siguientes son restricciones del manifiesto, no necesariamente versiones exactas instaladas. Las resoluciones concretas están en mobile/pubspec.lock.

| Componente | Restricción | Uso |
| --- | --- | --- |
| Dart SDK | >=3.0.0 <4.0.0 | Restricción del lenguaje; no es una versión de Flutter. |
| dio | ^5.7.0 | HTTP, interceptores, renovación de tokens, carga de archivos y SSE. |
| flutter_secure_storage | ^9.2.2 | Persistencia de credenciales mediante mecanismos seguros de la plataforma. |
| google_maps_flutter | ^2.10.0 | Mapa de incidencias. |
| geolocator | ^13.0.1 | Ubicación y permisos. |
| geocoding | ^5.0.0 | Conversión de coordenadas y direcciones. |
| image_picker | ^1.1.2 | Selección y captura de medios. |
| cached_network_image | ^3.4.1 | Presentación y caché de imágenes. |
| intl | ^0.19.0 | Formatos de fechas y números. |
| firebase_core | ^4.15.0 | Inicialización de Firebase. |
| firebase_messaging | ^16.7.0 | Permisos y token del dispositivo para FCM. |
| google_sign_in | ^7.2.0 | Cliente de acceso con Google. |
| sign_in_with_apple | ^8.2.0 | Cliente de acceso con Apple; integración del servidor pendiente. |
| video_player | ^2.14.0 | Reproducción de videos. |
| visibility_detector | ^0.4.0+2 | Detección de exposición de tarjetas para impresiones. |
| flutter_lints | ^5.0.0 | Reglas de análisis estático. |

flutter_bloc y cupertino_icons se retiraron por falta de uso. La implementación actual usa estado de widgets y notificadores compartidos; no debe describirse como una aplicación basada en BLoC.

### Flujos implementados

- Inicio con reportes, recientes, cerca de mí, populares e historial del autor.
- Registro e ingreso por correo, Google y Apple, edición de perfil y seguimiento.
- Sesión persistente: conserva credenciales al cerrar la app y renueva el acceso. Cerrar sesión, recuperar la contraseña o una revocación del servidor pueden invalidarla.
- Creación con fotos y video, progreso de subida, cancelación y reintentos.
- Carrusel horizontal de imágenes y video, reacciones y denuncias.
- Mapa real: reportes propios en verde y ajenos en rojo.
- Términos y política de privacidad disponibles desde la pantalla de ingreso.

Dio permite concentrar autenticación y errores de red en ApiClient. El almacenamiento seguro evita guardar tokens como preferencias ordinarias, pero no garantiza invulnerabilidad en dispositivos comprometidos. La caché de imágenes reduce descargas repetidas; no elimina todo consumo de red ni asegura retención permanente.

## 4. Backend y datos

### Dependencias actuales

| Componente | Versión declarada | Función |
| --- | --- | --- |
| .NET / ASP.NET Core | net10.0 | API, controladores e inyección de dependencias. |
| Microsoft.EntityFrameworkCore | 10.0.11 | Acceso a datos. |
| Npgsql.EntityFrameworkCore.PostgreSQL | 10.0.3 | Proveedor PostgreSQL. |
| Npgsql.EntityFrameworkCore.PostgreSQL.NetTopologySuite | 10.0.3 | Integración espacial del proveedor. |
| NetTopologySuite | 2.6.0 | Tipos y operaciones geoespaciales. |
| Microsoft.AspNetCore.Authentication.JwtBearer | 10.0.11 | Validación de tokens de acceso. |
| BCrypt.Net-Next | 4.2.0 | Hash de contraseñas. |
| Google.Apis.Auth | 1.77.0 | Validación de tokens de Google. |
| SixLabors.ImageSharp | 3.1.12 | Procesamiento y eliminación de metadatos de imágenes. |
| Microsoft.AspNetCore.OpenApi | 10.0.11 | Descripción de la API. |
| Scalar.AspNetCore | 2.17.10 | Interfaz de documentación. |

No se utiliza ASP.NET Identity como sistema de cuentas: la autenticación se implementa en los servicios del proyecto. Las dependencias PostgreSQL ya no están declaradas como versiones preview.

### Persistencia y ubicación

Docker Compose utiliza PostgreSQL 16 con PostGIS 3.4 y el volumen persistente rdreporta_pgdata. Monta database/scripts/ para la inicialización de una base nueva. Las semillas de database/seeds/ son material de referencia y mantenimiento; no deben darse por ejecutadas automáticamente.

Las consultas cercanas usan geometrías y operaciones espaciales del proveedor. La infraestructura espacial permite filtrar y ordenar por distancia; el rendimiento debe medirse con datos reales, sin asumir tiempos de respuesta específicos.

### Multimedia

IStorageService está conectado a LocalStorageService. Los archivos se guardan en backend/src/RdReporta.Api/wwwroot/uploads/ y no se versionan en Git. No hay integración activa de S3, R2 o MinIO.

Los videos se transfieren por bloques. La API contempla identificación del propietario, validación de bloques, reintentos e integridad. La app y la API comprueban un máximo de 3 minutos y 150 MiB; la API obtiene la duración del contenedor y rechaza archivos cuya duración no pueda verificarse. La presencia de estos controles no certifica la velocidad o estabilidad de cada conexión.

Las imágenes se decodifican, orientan y vuelven a guardar sin metadatos EXIF, XMP e IPTC, con límites de resolución. La conservación y limpieza de archivos físicos tras eliminar una cuenta requiere revisión antes de un lanzamiento público.

### Reacciones, vistas y popularidad

- Las vistas se registran mediante el flujo de impresiones; los clientes comparten el contador de un mismo reporte.
- La API publica actualizaciones por SSE en /api/posts/views/live.
- El distribuidor de eventos es local a una instancia; varias réplicas requieren un mecanismo compartido.
- Popular esta semana consulta reportes activos de los últimos siete días y ordena por **reacciones × 2 + vistas × 0.1**, con desempate por fecha.
- El estado de una publicación sigue existiendo para administración y visibilidad, aunque no se muestre una píldora de estado en la interfaz pública.

## 5. Autenticación y controles de seguridad

- Tokens de acceso JWT y renovación mediante refresh tokens.
- Refresh tokens almacenados como SHA-256 y rotados al renovar; contraseñas protegidas con BCrypt.
- Configuración privada de Jwt:SecretKey y ConnectionStrings:DefaultConnection, sin valores de respaldo.
- Límites de solicitudes globales y política de autenticación de 15 solicitudes por minuto por IP.
- Comprobaciones de propiedad para archivos y operaciones sobre reportes.
- Claves persistentes de ASP.NET Data Protection para los flujos que las utilizan.
- HTTP de desarrollo separado de la configuración Android de release; producción requiere HTTPS.
- Firma Android de producción con configuración privada, sin reutilizar automáticamente la firma debug.

Estos controles reducen riesgos concretos. No constituyen una garantía absoluta de seguridad ni una certificación de auditoría completa.

## 6. Panel administrativo

React 19, TypeScript ~6.0.2, Vite ^8.3.0, lucide-react ^1.48.0 y oxlint ^1.81.0.

La estructura actual incluye layouts, páginas, componentes y un cliente API. Contiene flujos de acceso, publicaciones, denuncias, categorías, usuarios y métricas. El cliente conserva la sesión del panel en sessionStorage; no se ha migrado a cookies HttpOnly.

**Estado de compilación:** el último npm run build, durante la limpieza del 1 de octubre, falló por errores de ThemeSelector.tsx, importaciones que requieren import type y una importación de FormEvent sin uso. Esos archivos no se modificaron en la limpieza. El panel no debe describirse como listo para despliegue.

React organiza la interfaz y TypeScript ayuda a detectar errores, pero sus tipos no validan por sí solos todos los datos recibidos en ejecución. No se afirman tiempos fijos de compilación ni comparaciones de velocidad sin mediciones actuales.

## 7. Integraciones pendientes o parciales

| Área | Implementado | Pendiente |
| --- | --- | --- |
| Google | Cliente y validación del token en el servidor. | Configuración final y prueba integral con el proveedor. |
| Apple | Cliente móvil que llama a /auth/apple. | Endpoint de la API, validación del token y configuración del proveedor. |
| Firebase/FCM | Inicialización y registro de tokens de dispositivos. | Envío remoto push y comprobación de recepción en segundo plano. |
| Recuperación | Formularios, endpoints y protección del código. | SMTP configurado y entrega real de correos. |
| Maps | Visualización con marcadores. | Selección de ubicación de un reporte tocando el mapa y validación de claves por plataforma. |
| Archivos | Almacenamiento local y procesamiento de imágenes. | Proveedor remoto, política de retención y limpieza. |
| Producción | Controles y configuración base. | Dominio, HTTPS, credenciales, firma final y validación Android/iOS. |

## 8. Revisión, pruebas y mantenimiento

scripts/run_audit.ps1 reúne 11 comprobaciones locales y una adicional si se proporciona la dirección de la API. Incluye compilación, dependencias, controles de carga e imágenes, pruebas/análisis móvil y revisiones del panel. Es una herramienta para ejecutar una auditoría: su existencia no implica que el estado actual apruebe todos los controles.

scripts/check_admin.cjs navega el panel con respuestas API controladas y guarda capturas. No certifica la conexión real a PostgreSQL ni a proveedores externos.

**Evidencia reciente:**

- Tras la limpieza: flutter analyze --no-pub terminó sin problemas.
- La compilación del administrador falló por los errores descritos anteriormente.
- En la limpieza no se ejecutaron pruebas ni se recompiló el APK.
- Las evidencias de auditorías anteriores están en AUDITORIA_Y_SEGURIDAD.md; no equivalen a una nueva ejecución sobre cada cambio.
- No se afirma un número fijo de pruebas ni un “100 % aprobado” para el estado actual.

Se retiraron archivos desconectados y dependencias sin uso. El respaldo local de 20 archivos está en maintenance/archive/cleanup-2026-10-01.zip, excluido de Git; puede contener scripts administrativos y no debe publicarse. Las cachés y los datos de usuarios se conservaron.

AGENTS.md y GEMINI.md contienen instrucciones para usar CodeGraph, limitar lecturas y evitar trabajo ajeno a la tarea.

## 9. Documentación relacionada

- [README: ejecución y estado resumido](README.md).
- [Configuración de servicios y producción](CONFIGURACION_SERVICIOS.md).
- [Auditoría y seguridad](AUDITORIA_Y_SEGURIDAD.md).
- [Inventario y limpieza de archivos](docs/AUDITORIA_ARCHIVOS_SIN_USO.md).
- [Información del respaldo local](maintenance/README.md).

INTEGRACIONES_Y_PENDIENTES.md conserva una revisión anterior con afirmaciones desactualizadas. Este resumen y el README describen el estado revisado del 1 de octubre; las futuras modificaciones deben reflejarse en estos documentos.
