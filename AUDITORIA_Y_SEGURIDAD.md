# Auditoría y seguridad de RDReporta

**Actualización:** 5 de octubre de 2026
**Alcance:** Flutter/Android/iOS, API .NET 10, PostgreSQL/PostGIS, panel React, cargas multimedia y cadena de suministro.
**Objetivo:** convertir requisitos en controles verificables, conservar evidencia histórica y priorizar los riesgos pendientes.

Esta guía documenta los controles de seguridad y los resultados verificados en el código actual. **No constituye una certificación formal de cumplimiento por terceros ni una prueba de penetración externa.**

## 1. Estado ejecutivo y evidencia

### 1.1 Evidencia histórica registrada: 30 de septiembre

El documento anterior registró los siguientes resultados:

| Área | Resultado registrado | Límite |
| --- | --- | --- |
| Backend | Compilación sin errores ni advertencias. | No se volvió a compilar en aquella fecha. |
| Dependencias | NuGet y npm sin vulnerabilidades conocidas informadas en aquella consulta. | Depende de fecha, fuentes, cobertura y éxito del escaneo. |
| Video de 52.2 MiB | Integridad, reintentos, conflictos y propietario comprobados en servidor. | No certifica estabilidad ni velocidad desde un teléfono. |
| Imágenes | JPEG/PNG/WebP reales, orientación y eliminación de metadatos; rechazo de archivos dañados. | No certifica antivirus ni todas las entradas posibles. |
| Flutter | 26 pruebas aprobadas y análisis sin hallazgos. | Número histórico; se retiró después una prueba de un componente desconectado. |
| Panel | Linter y compilación aprobados entonces. | La compilación posterior falló; resuelto el 5 de octubre de 2026. |
| API y PostgreSQL | Registro, permisos, propiedad, rotación, reutilización y logout comprobados. | Casos concretos del script, no todas las rutas ni todos los roles. |
| Android | APK debug compilado y comprobaciones de configuración. | No equivale a analizar el binario release firmado. |
| Script de auditoría | 12/12 controles informados como aprobados. | Incluye HTTP local; no cubre todos los controles de este documento. |

### 1.2 Evidencia del 1 de octubre

- Limpieza de dependencias y archivos no utilizados; `flutter analyze --no-pub` completado sin errores.
- Se identificó fallo de compilación en el panel React (`admin/`) por discrepancias de tipos en `ThemeSelector.tsx`, tipos de Vite y `FormEvent`.

### 1.3 Evidencia de verificación e implementaciones: 5 de octubre de 2026

- **Compilación del Panel Web Administrativo (admin/):** Resuelto. Se agregaron los tipos e importaciones correctos y la propiedad `compact?: boolean` en `ThemeSelector.tsx`. `npm run build` (`tsc -b && vite build`) ejecuta y finaliza con **0 errores**, transformando 1896 módulos y generando los artefactos en `dist/` en 1.01 segundos.
- **Iniciar sesión con Apple (Sign in with Apple):** Implementado endpoint `POST /api/auth/apple` y servicio `AppleAuthService`. Valida la firma criptográfica RSA del identity token contra el endpoint JWKS oficial de Apple (`https://appleid.apple.com/auth/keys`), con almacenamiento en caché (24 horas) y recarga ante claves no reconocidas; valida emisor (`https://appleid.apple.com`), audiencia (`Authentication:AppleBundleId`), expiración y verificación del correo; extrae `sub` y correo determinista privado, e integra con `AuthService.ExternalLoginAsync`. En Flutter (`api_client.dart` y `login_screen.dart`), se transmite `fullName` en la primera autorización.
- **Almacenamiento multimedia en la nube:** Implementado `S3StorageService` con soporte configurable para Cloudflare R2, AWS S3, Google Cloud Storage (interoperabilidad S3) y dominios CDN públicos (`Storage:Provider=S3/R2/Cloud`). `LocalStorageService` permanece disponible para desarrollo local. El controlador de video por bloques (`VideoChunksController`) traslada el video ensamblado a la nube si está configurada, y `UploadReference.cs` valida propiedad y seguridad de archivos tanto en rutas locales `/uploads/...` como en URLs remotas absolutas de CDN sin queries ni saltos de directorio.
- **Backend .NET 10:** Compilación de la solución completa (`RdReporta.Api`, `RdReporta.Infrastructure`, `RdReporta.Application`, `RdReporta.Domain`) con **0 errores y 0 advertencias**.
- **Pruebas de seguridad de imágenes (`ImageSecurityChecks`):** Ejecutada y aprobada. Verificación de decodificación real JPEG, PNG y WebP, conservación de orientación EXIF, eliminación de metadatos privados (EXIF, XMP, IPTC, bloques de texto PNG), rechazo de archivos corruptos y verificación estricta de propiedad de URL de carga.
- **Pruebas de carga de video (`VideoUploadChecks`):** Ejecutada y aprobada. 52.2 MiB ensamblado en bloques con SHA-256, reintentos idempotentes y aislamiento por propietario.
- **Pruebas móviles:** `flutter analyze` 0 errores; `flutter test test/api_client_test.dart test/auth_flow_test.dart` superadas (11/11 pruebas aprobadas).

### 1.4 Controles implementados en el código actual

Configuración privada obligatoria de JWT/DB; contraseñas BCrypt; refresh tokens con SHA-256 y consumo atómico; controles de propiedad en publicaciones y archivos; saneamiento de imágenes y metadatos; límites de solicitudes y tamaño de carga; CORS configurado; separación debug/release; autenticación federada con Google y Apple; almacenamiento local y en la nube (S3/R2/GCS); exclusión de medios y secretos de Git.

## 2. Referencias consultadas y aplicación

Se redactaron criterios propios para RDReporta, sin copiar listas completas. Los identificadores RD-* son internos y **no son identificadores oficiales OWASP**.

| Repositorio y Markdown consultado | Uso en esta guía |
| --- | --- |
| [OWASP ASVS, README de v5.0.0](https://github.com/OWASP/ASVS/blob/v5.0.0/README.md) | Requisitos verificables para API/panel y referencias con versión. Se propone ASVS nivel 2 como objetivo de evaluación, no como nivel alcanzado. |
| [OWASP MASVS, README](https://github.com/OWASP/owasp-masvs/blob/master/README.md) | Cobertura de seguridad y privacidad móvil. |
| [OWASP MASTG, README](https://github.com/OWASP/owasp-mastg/blob/master/README.md) | Método de pruebas móviles y análisis del binario. |
| [OWASP API Security Top 10, edición 2023](https://github.com/OWASP/API-Security/blob/master/editions/2023/en/0x11-t10.md) | Inventario de riesgos API; no sustituye una matriz completa de verificación. |
| [OWASP WSTG, README](https://github.com/OWASP/wstg/blob/master/README.md) | Procedimientos de evaluación web. Para ejecutar, fijar una versión de escenarios; la referencia consultada identifica 4.2 como publicación estable. |
| [OWASP File Upload Cheat Sheet](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/File_Upload_Cheat_Sheet.md) | Defensa de cargas y recuperación de archivos mediante varias capas. |
| [OWASP Session Management Cheat Sheet](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Session_Management_Cheat_Sheet.md) | Protección de sesiones web, cookies y revocación. |
| [OWASP Logging Cheat Sheet](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Logging_Cheat_Sheet.md) | Eventos de seguridad y exclusión de secretos en registros. |
| [MobSF, README](https://github.com/MobSF/Mobile-Security-Framework-MobSF/blob/master/README.md) | Análisis estático/dinámico de aplicaciones móviles; resultados sujetos a revisión manual. |
| [OpenSSF Scorecard, README](https://github.com/ossf/scorecard/blob/main/README.md) | Revisiones del repositorio, permisos, dependencias y procesos de entrega. |

ASVS está fijado al tag consultado. Las referencias master/main son móviles: al ejecutar una evaluación, registrar el commit o versión exactos de cada guía y herramienta. Consultar README no demuestra que se hayan verificado todos los requisitos del repositorio.

## 3. Cómo registrar una auditoría

### Estados permitidos

| Estado | Significado |
| --- | --- |
| Verificado | Prueba completada con resultado esperado y evidencia vinculada a una revisión/binario. |
| Implementado, por verificar | Código o configuración presente, sin evidencia suficiente de ejecución actual. |
| Parcial | Solo se cubren algunas condiciones del control. |
| Fallido | Existe una comprobación reproducible que no cumple el criterio. |
| Pendiente | Aún no ejecutado o no implementado. |
| No aplica | Justificación específica, revisada y fechada. |

Un escaneo que falla o no consulta su fuente no se registra como “cero vulnerabilidades”. No calcular una aprobación global a partir de un subconjunto.

### Ficha mínima de evidencia

- ID interno, requisito/versiones de referencia y superficie evaluada.
- Fecha, responsable, commit y resumen de cambios locales sin commit.
- Entorno, roles/cuentas de prueba y configuración relevante, sin secretos.
- Versión de herramienta; para binarios, hash SHA-256, tipo debug/release y firma.
- Pasos reproducibles, resultado esperado/observado y archivo de evidencia.
- Severidad justificada, corrección, responsable y fecha objetivo.
- Reprueba sobre la versión corregida; excepciones con vencimiento.

Guardar registros y capturas depurados en artifacts/ o almacenamiento privado. No versionar tokens, credenciales, correos reales ni coordenadas sensibles. El ZIP de maintenance/archive/ es respaldo local, no evidencia para publicar.

## 4. Modelo de amenazas del proyecto

| Activo/frontera | Amenaza que debe comprobarse |
| --- | --- |
| Invitado → API | Escrituras sin sesión, extracción masiva o abuso de recursos. |
| Ciudadano A → objetos de B | Modificación/borrado de reportes, medios, perfil o tokens de dispositivo ajenos. |
| Ciudadano → moderación | Acceso a roles o funciones privilegiadas y cambios de estado no autorizados. |
| Móvil/panel → sesión | Robo de tokens, reutilización de renovación y revocación incompleta. |
| Carga → almacenamiento → publicación | Archivo dañino, agotamiento de disco, acceso directo a medios retirados. |
| API → Google/SMTP/FCM | Respuestas no confiables, credenciales inválidas, caídas y filtración de datos. |
| Repositorio/CI → release | Dependencia comprometida, permisos excesivos o binario diferente del auditado. |
| Cuenta/datos → respaldo/eliminación | Medios huérfanos, borrado incompleto y restauración insegura. |

Usar como mínimo invitado, dos ciudadanos distintos, moderador y administrador en las evaluaciones de permisos. Separar datos de pruebas y datos reales.

## 5. Matriz de controles del proyecto

La situación inicial refleja evidencia anterior o código revisado; cada fila necesita su propia ficha para pasar a Verificado.

| ID | Control y criterio de aceptación | Estado inicial |
| --- | --- | --- |
| RD-AUTH-01 | Firma, audiencia, emisor y vencimiento JWT válidos; rechazar alteraciones. | Implementado, por verificar. |
| RD-AUTH-02 | Renovación concurrente consume el token una vez; el anterior se rechaza. | Evidencia histórica; repetir tras cambios. |
| RD-AUTH-03 | Logout, recuperación y revocación tienen efectos documentados en access/refresh y múltiples dispositivos. | Parcial. |
| RD-AUTH-04 | Sesión persistente resiste cierre/arranque y caída de red; secretos nunca en logs. | Implementado, por verificar. |
| RD-AUTH-05 | Google y Apple validados criptográficamente en servidor (GoogleJsonWebSignature / Apple JWKS); cliente móvil conectado. | Implementado; verificación E2E con cuentas reales pendiente. |
| RD-AUTH-06 | Recuperación: respuesta neutral, caducidad, consumo único, concurrencia y entrega SMTP. | Código/evidencia parcial; entrega pendiente. |
| RD-API-01 | Operaciones sobre IDs ajenos se rechazan y no cambian datos. | Evidencia histórica parcial. |
| RD-API-02 | Solo roles autorizados crean categorías, moderan o acceden a administración. | Evidencia histórica parcial. |
| RD-API-03 | DTO no admite cambios de rol/propietario ni expone secretos, correo privado o tokens. | Pendiente de matriz completa. |
| RD-API-04 | Tamaños, paginación, conexiones SSE y cargas tienen límites medidos. | Parcial. |
| RD-API-05 | Crear/reaccionar/seguir/ver no permite inflar contadores o automatizar abuso sin límites. | Pendiente de pruebas de abuso. |
| RD-UP-01 | Extensión, contenido, propietario y rutas se validan; soporte local y cloud (S3/R2/GCS). | Verificado en pruebas automatizadas. |
| RD-UP-02 | Imágenes mantienen orientación y pierden metadatos; entradas dañadas se rechazan. | Verificado (ImageSecurityChecks). |
| RD-UP-03 | Bloques repetidos/conflictivos, cancelación y finalización no corrompen archivos; traslado a nube soportado. | Verificado (VideoUploadChecks). |
| RD-UP-04 | Medio oculto/eliminado cumple la política al consultar su URL directa. | Pendiente de verificar. |
| RD-UP-05 | Cuotas, temporales huérfanos y eliminación física tienen política y comprobación. | Pendiente. |
| RD-WEB-01 | Contenido de reportes/perfiles no ejecuta scripts; panel web compila sin errores (npm run build). | Compilación verificada; CSP dinámico pendiente. |
| RD-WEB-02 | Tokens del panel no quedan accesibles innecesariamente a JavaScript; migración de sesión evaluada. | sessionStorage actual; mejora pendiente. |
| RD-WEB-03 | Si se adoptan cookies, se implementan Secure/HttpOnly/SameSite y defensa CSRF adecuada. | Pendiente, condicionado a migración. |
| RD-MOB-01 | Revisar almacenamiento, copias, logs y caché en Android/iOS release. | Configuración presente; binario pendiente. |
| RD-MOB-02 | Permisos denegados/revocados y GPS apagado no bloquean ni publican ubicación incorrecta. | Implementación presente; prueba real pendiente. |
| RD-MOB-03 | Componentes exportados, enlaces y navegación no permiten acciones privilegiadas. | Pendiente de cobertura completa. |
| RD-MOB-04 | Binario firmado auditado con MobSF y procedimientos MASTG seleccionados. | Pendiente. |
| RD-OPS-01 | HTTPS, cabeceras, CORS y confianza del proxy funcionan en el despliegue real. | Configuración base; despliegue pendiente. |
| RD-OPS-02 | Respaldos DB/medios/claves se restauran y cumplen retención definida. | Pendiente. |
| RD-OPS-03 | Logs depurados, alertas, acceso y retención documentados. | Pendiente. |
| RD-SUP-01 | Escaneos exitosos de dependencias y secretos actuales/históricos, con revisión de alertas. | Evidencia histórica limitada. |
| RD-SUP-02 | CI con permisos mínimos, revisiones y dependencias/actions fijadas apropiadamente. | CodeQL/Dependabot configurados; verificación pendiente. |
| RD-PRIV-01 | Política coincide con datos reales, terceros, eliminación y retención. | Versión de desarrollo; plazos pendientes. |

### Cobertura de API Security 2023

Aplicación propuesta de los diez riesgos, basada en la [edición consultada](https://github.com/OWASP/API-Security/blob/master/editions/2023/en/0x11-t10.md):

| Riesgo | Revisión específica en RDReporta |
| --- | --- |
| API1: objetos | Cambiar IDs de reportes, perfiles, cargas y dispositivos. |
| API2: autenticación | Tokens, recuperación y acceso externo. |
| API3: propiedades | Campos editables y datos privados de DTO. |
| API4: recursos | Disco, imágenes, video, correo y SSE. |
| API5: funciones | Endpoints de moderador/administrador. |
| API6: flujos sensibles | Automatización de publicaciones e interacciones. |
| API7: SSRF | Verificar si alguna función descarga URLs externas; justificar si no aplica. |
| API8: configuración | CORS, HTTPS, errores y secretos. |
| API9: inventario | Rutas activas, debug y clientes desactualizados. |
| API10: terceros | Validación y fallos de proveedores. |

## 6. Procedimientos prioritarios

### 6.1 Cargas y publicación de medios

Revisión adaptada de [File Upload Cheat Sheet](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/File_Upload_Cheat_Sheet.md). Ejecutar con archivos de prueba en entorno aislado y límites de recursos.

- Probar extensiones dobles, MIME engañoso, rutas manipuladas y contenedores truncados.
- Comprobar nombres generados, propiedad y límites reales de la carga.
- Separar validación del contenedor de validación del contenido: una cabecera correcta no garantiza un archivo inocuo.
- Revisar almacenamiento público actual bajo wwwroot; decidir si se necesita servicio de medios con control de acceso o almacenamiento aislado.
- Comprobar enlaces directos después de ocultar/eliminar publicaciones y tras eliminar una cuenta.
- Medir acumulación de cargas canceladas y reintentos; definir cuotas y limpieza.
- Evaluar escaneo antimalware según los formatos y riesgo. No declararlo implementado.

Criterio: rechazo sin archivos finales inválidos, sin apropiación de cargas ajenas y sin acceso que contradiga la política de publicación.

### 6.2 Sesiones persistentes y panel

La persistencia móvil solicitada se conserva como decisión de producto; no se añade caducidad silenciosamente. Documentar riesgo, revocación, sesiones/dispositivos y reautenticación de acciones sensibles.

El panel utiliza sessionStorage, accesible desde JavaScript. La [guía de sesiones](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Session_Management_Cheat_Sheet.md) sirve para evaluar una migración a cookies: HttpOnly limita lectura del token, pero no elimina XSS ni acciones de un atacante dentro de la sesión. SameSite no reemplaza toda protección CSRF.

Comprobar logout sin red y explicar qué credenciales quedan válidas en servidor; no confundir borrado local con revocación inmediata del JWT.

### 6.3 Registro de eventos y respuesta

Según [Logging Cheat Sheet](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Logging_Cheat_Sheet.md), registrar eventos útiles sin incluir directamente tokens, contraseñas, cadenas de conexión o claves.

Propuesta: ID de correlación, fecha UTC, tipo de evento, actor seudonimizado, objeto y resultado. Depurar cuerpos de solicitud, geolocalización y datos personales. Revisar acceso, retención y falsificación de líneas de log.

Preparar un procedimiento para revocar credenciales, preservar evidencia, comunicar incidentes y volver a verificar la corrección.

### 6.4 Binario móvil y cadena de suministro

[MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF/blob/master/README.md) permite revisar artefactos móviles. Usar el candidato release real en un entorno privado; conservar hash, versión y resultado. Revisar manualmente falsos positivos y limitaciones en código Dart compilado.

La revisión del repositorio toma [OpenSSF Scorecard](https://github.com/ossf/scorecard/blob/main/README.md) como apoyo: comprobar permisos de CI, revisión de cambios, actualización de paquetes y dependencias fijadas. El workflow actual usa tags de Actions; evaluar pinning por SHA y actualización controlada. No hay Scorecard ejecutado en esta revisión.

CodeQL local está configurado para C# y JavaScript/TypeScript, no demuestra cobertura del código Dart. Registrar cada ejecución de GitHub y resolver sus alertas, no solo la existencia del YAML.

## 7. Backlog de riesgos y dependencias

Prioridades propuestas por impacto y exposición; no representan vulnerabilidades explotadas ni puntuaciones CVSS calculadas.

| Prioridad | Acción | Criterio de cierre |
| --- | --- | --- |
| Alta | Rotar secretos/contraseñas históricos que sigan válidos y evaluar historial Git. | Credenciales antiguas rechazadas; escaneo completo documentado. |
| Alta | Revisar acceso directo a medios ocultos/eliminados y eliminación física. | Política definida y casos de acceso/borrado verificados. |
| Alta | Completar matriz de propiedad y roles en todas las escrituras. | Invitado/A/B/moderador/admin evaluados con evidencia. |
| Alta antes del lanzamiento | Producir y empaquetar candidatos release del panel web y aplicaciones. | Compilación de admin/ corregida y verificada (npm run build). Pendiente empaquetado para servidor web. |
| Alta antes del lanzamiento | Configurar despliegue HTTPS, respaldos y restauración. | Prueba del entorno y restauración satisfactoria. |
| Media | Reducir exposición de tokens del panel; evaluar MFA para cuentas privilegiadas. | Diseño aprobado, controles implementados y evaluados. |
| Media | Validar Apple, Google, FCM y SMTP en entorno real con credenciales activas. | Endpoints y validación criptográfica de Apple y Google completados; pruebas en dispositivos reales y envío SMTP pendientes. |
| Media | Controlar consumo y abuso de cargas, SSE e interacciones. | Límites y respuesta medidos con carga acotada. |
| Media | Firmar/auditar binario Android y verificar iOS. | Evidencia vinculada a artefactos finales. |
| Media | Retención, eliminación, política y alertas. | Plazos definidos y comportamiento probado. |
| Media | Confirmar CI remoto y revisar licencias. | Ejecuciones, alertas resueltas y decisiones registradas. |
| Baja funcional | Outbox, recuperación de borradores y monitoreo de rendimiento. | Casos medidos; no afirmar que ya existen. |

La [licencia de ImageSharp 3.1.12](https://github.com/SixLabors/ImageSharp/blob/v3.1.12/LICENSE) debe revisarse si cambian las condiciones comerciales. Una ausencia histórica de CVE no decide obligaciones de licencia.

## 8. Calidad funcional, privacidad y accesibilidad

Estas comprobaciones complementan seguridad; no deben contabilizarse como controles de seguridad aprobados solo por tener interfaz.

| Área | Escenarios de aceptación |
| --- | --- |
| Formularios y carga | Teclado, texto largo, doble envío, errores parciales y reintentos. |
| Ubicación | Permisos revocados, posición obsoleta, precisión insuficiente y edición manual. |
| Arranque | Sin sesión → login; sesión válida → restauración; caída de red → conservar credenciales sin inventar autenticación válida. |
| Multimedia | Fotos completas, carrusel, pausa al cambiar página y cancelación de carga. |
| Vistas | Mismo contador entre módulos, reconexión SSE y deduplicación de impresiones. |
| Moderación | Roles reales, denuncias repetidas, contenido retirado y trazabilidad. |
| Accesibilidad | Contraste medido, texto ampliado, lector de pantalla, foco y objetivos táctiles en ambos temas. |
| Rendimiento | RAM, batería, fluidez y transferencia medidas en dispositivos reales. |
| Privacidad | Perfil público frente a correo privado, coordenadas voluntarias, eliminación y terceros. |
| Compatibilidad | Versiones/arquitecturas reales del candidato; no porcentajes de cobertura inventados. |

No afirmar anonimato de reportes identificados, cumplimiento WCAG por la paleta, pinning implementado, almacenamiento invulnerable o ausencia de rastreo de terceros sin comprobarlo.

## 9. Ejecución reproducible

**No se ejecutaron estos comandos al actualizar el documento.** Cuando se autorice la auditoría, usar un entorno de pruebas y conservar salidas/errores completos en privado.

Desde la raíz:

    .\scripts\run_audit.ps1

Para incluir HTTP, iniciar antes la API de auditoría y su PostgreSQL local:

    .\scripts\run_audit.ps1 -ApiBaseUrl http://127.0.0.1:5001/api

La comprobación HTTP crea y elimina una cuenta temporal mediante el contenedor rdreporta_postgres. No ejecutarla contra producción ni apuntarla a datos reales.

El script actual reúne 11 controles locales y uno HTTP opcional. Sus límites:

- La búsqueda de secretos identifica patrones conocidos en archivos rastreados; no sustituye escaneo general del historial.
- Las comprobaciones de configuración son patrones de texto, no inspección del comportamiento release.
- npm usa un umbral de alta/crítica; un exit code satisfactorio no implica cero hallazgos de cualquier severidad.
- Las pruebas de servidor de imágenes/video no certifican transferencia móvil real.
- No ejecuta automáticamente todos los procedimientos ASVS/MASTG/WSTG, MobSF o Scorecard.

## 10. Criterios para publicar

- Candidato identificado por commit, cambios locales, hash y firma.
- Compilaciones/análisis/pruebas aplicables completados, con resultados actuales.
- Riesgos críticos/altos corregidos o excepción explícita documentada con vencimiento.
- Propiedad/roles, cargas, sesión y privacidad verificados sobre ese candidato.
- Servicios externos utilizados comprobados; los incompletos no se presentan como disponibles.
- HTTPS, cuotas, respaldos, restauración y monitoreo operativos.
- Política de privacidad y eliminación coinciden con el comportamiento real.
- Repruebas documentadas tras cada corrección relevante.

No utilizar “100 % seguro”, “certificado OWASP” ni “auditoría aprobada” sin alcance, fecha y evidencia. Esta guía organiza la evaluación; los controles pendientes siguen pendientes.

## 11. Historial y documentación relacionada

| Fecha | Cambio |
| --- | --- |
| 30/09/2026 | Auditoría automatizada anterior, 12/12 controles registrados y 26 pruebas móviles. |
| 01/10/2026 | Limpieza de archivos/dependencias; análisis móvil correcto y compilación del panel fallida. |
| 01/10/2026 | Revisión documental con fuentes GitHub, estados de evidencia, modelo de amenazas y matriz RD-*. Sin nueva ejecución de pruebas. |
| 05/10/2026 | Implementación de Sign in with Apple (/api/auth/apple con validación JWKS oficial), servicio en la nube S3StorageService (R2/S3/GCS/CDN) con UploadReference adaptado, y corrección de compilación TypeScript en admin/ (npm run build aprobado con 0 errores). Pruebas de seguridad de imágenes y videos revalidadas exitosamente. |

Consultar [README](README.md), [configuración de servicios](CONFIGURACION_SERVICIOS.md), [resumen técnico](RESUMEN_PROYECTO.md) e [inventario de limpieza](docs/AUDITORIA_ARCHIVOS_SIN_USO.md). Si cambian implementación o resultados, actualizar la evidencia y sus fechas.
