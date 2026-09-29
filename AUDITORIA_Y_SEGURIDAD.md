# Guía Maestra de Buenas Prácticas, Seguridad Móvil y Checklist de Validaciones

**Proyecto:** RDReporta  
**Fecha de actualización:** 28 de septiembre de 2026  
**Alcance:** Cliente Móvil (Flutter / Android / iOS), API Backend (.NET 10) y Panel Web Administrativo (React / Vite).  
**Estándares de referencia:** OWASP Mobile Top 10 (2024), OWASP MASVS (Mobile Application Security Verification Standard), WCAG 2.1 AA, Google Play Data Safety, Apple Privacy Nutrition Labels.

---

## 1. Buenas Prácticas de Código y Arquitectura en Aplicaciones Móviles

### 1.1 Arquitectura Limpia y Separación de Responsabilidades (Clean Architecture)
- **Capa de Dominio (Domain):** Entidades inmutables, reglas de negocio puras, sin dependencias de frameworks ni paquetes de red o persistencia.
- **Capa de Datos (Data):** Fuentes remotas (`ApiClient` con Dio) y locales (`FlutterSecureStorage`, caché local). Repositorios que abstraen el origen de los datos.
- **Capa de Presentación (Presentation / UI):** Widgets reactivos, desacoplados mediante gestión de estado (`ValueNotifier`, `BLoC`), manteniendo la lógica de negocio fuera de los métodos `build()`.
- **Estructura Modular (Feature-First):** Cada funcionalidad (`auth`, `feed`, `map`, `posts`, `profile`) encapsula sus propias vistas, controladores y componentes.

### 1.2 Principios S.O.L.I.D. y Código Defensivo
- **Single Responsibility (SRP):** Cada clase tiene una única razón de cambio (ej. `LocationService` solo gestiona GPS; `ApiClient` solo coordina peticiones HTTP).
- **Open/Closed (OCP):** Comportamientos extensibles mediante abstracciones (ej. `HttpClientAdapter` intercambiable para pruebas unitarias sin tocar la red real).
- **Liskov Substitution (LSP):** Clientes de prueba (`FakeAdapter`) sustituyen al cliente HTTP real sin romper expectativas del contrato.
- **Interface Segregation (ISP):** Clases consumidoras dependen solo de los métodos que necesitan.
- **Dependency Inversion (DIP):** Las pantallas y controladores dependen de abstracciones y singletons controlados, permitiendo inyección de dependencias para tests.

---

## 2. Brechas de Seguridad en Aplicaciones Móviles (OWASP Mobile Top 10 - 2024)

| Código | Riesgo OWASP Mobile (2024) | Impacto / Vector de Ataque | Mitigación Implementada y Recomendada |
|---|---|---|---|
| **M1** | **Improper Credential Usage** | Credenciales de API o tokens expuestos en repositorios de código o en strings compilados. | Cero API keys o contraseñas en código. Inyección en compilación vía `--dart-define` o variables de entorno del sistema. Tokens JWT almacenados exclusivamente en hardware-backed storage. |
| **M2** | **Inadequate Supply Chain Security** | Paquetes de terceros o plugins con vulnerabilidades críticas conocidas (CVEs). | Auditoría automatizada con `dotnet list package --vulnerable` en backend y verificación periódica de dependencias en `pubspec.yaml` mediante análisis estático y dependabot. |
| **M3** | **Insecure Authentication / Authorization** | Sesiones que no expiran, ausencia de invalidación de refresh tokens, falta de control de roles (IDOR). | Access Tokens JWT de corta duración + Refresh Tokens rotativos almacenados de forma segura. Autorización estricta por roles (`Admin`, `Moderator`, `Citizen`) validada en servidor. |
| **M4** | **Insufficient Input/Output Validation** | Inyecciones SQL, NoSQL, Cross-Site Scripting (XSS) en WebViews, manipulación de payloads. | Sanitización y validación estricta de tipos tanto en cliente (Form Validators) como en servidor (Entity Framework Core con queries parametrizadas y DataAnnotations). |
| **M5** | **Insecure Communication** | Intercepción de tráfico de red en tránsito (Man-In-The-Middle, redes Wi-Fi públicas no cifradas). | Transporte HTTPS obligatorio con TLS 1.3/1.2. Deshabilitación de `usesCleartextTraffic` en Android y `NSAllowsArbitraryLoads` en iOS. Recomendación de SSL/Certificate Pinning. |
| **M6** | **Inadequate Privacy Controls** | Fuga de PII (Personally Identifiable Information), metadatos de ubicación residencial o EXIF en imágenes. | Filtrado de metadatos GPS al subir imágenes; no vinculación de nombres reales con reportes anónimos. Cumplimiento estricto con las políticas de privacidad de Google Play y App Store. |
| **M7** | **Insufficient Binary Protections** | Ingeniería inversa, desensamblado con herramientas como Frida, Ghidra o Jadx para extraer secretos. | Activación de ProGuard / R8 en Android. Ofuscación de símbolos en Flutter con `--obfuscate --split-debug-info`. Eliminación de logs verbosos en builds de release. |
| **M8** | **Security Misconfiguration** | Permisos excesivos en el manifiesto, `android:exported=true` en componentes no protegidos, modo debug en producción. | Revisión de `AndroidManifest.xml` e `Info.plist`: únicamente permisos esenciales. Servicios y Activities internos con `android:exported="false"`. `debugShowCheckedModeBanner: false`. |
| **M9** | **Insecure Data Storage** | Almacenamiento de tokens o datos sensibles en `SharedPreferences` o `UserDefaults` en texto plano. | Uso mandatorio de `flutter_secure_storage`: Keystore con cifrado AES-256-GCM / EncryptedSharedPreferences en Android y Keychain con `kSecAttrAccessibleAfterFirstUnlock` en iOS. |
| **M10** | **Insufficient Cryptography** | Uso de algoritmos obsoletos (MD5, SHA1, DES) o generación de números pseudoaleatorios predecibles. | Algoritmos robustos estándar (HMAC-SHA256 para firmas de tokens, PBKDF2/Argon2 para hashes de contraseñas en backend, AES-256-GCM para almacenamiento). |

---

## 3. Matriz Exhaustiva de Validaciones (Las 20 Áreas del Checklist)

### 3.1 Loading States (Estados de Carga y Prevención de Multi-Tap)
- **Indicadores Visuales Claros:**
  - Spinners contextuales (`CircularProgressIndicator`) en botones de acción y barras de navegación.
  - Skeletons / Shimmer placeholders en listas (`ListView`) y tarjetas de incidencias para evitar saltos de interfaz (layout shift).
- **Mitigación de Multi-Tap (Doble Submit):**
  - Flags de estado `_busy` o `_loading`: deshabilitar botones (`onPressed: _busy ? null : _action`) en el momento exacto en que se dispara una petición asíncrona.
  - Cancelación o descarte de eventos repetidos mediante debounce/throttle.
- **Manejo de Tiempos de Espera (Timeouts):**
  - Timeouts de conexión y recepción configurados en `ApiClient` (10 segundos). Si se excede, mostrar estado de reintento (`RequestState`) sin bloquear la interfaz.

### 3.2 Validación y Pruebas de Formularios
- **Gestión de Estado de Formulario:**
  - Uso de `GlobalKey<FormState>()` para validar atomicamente todos los campos antes del envío.
  - `AutovalidateMode.onUserInteraction` tras el primer intento de envío, ofreciendo retroalimentación inmediata sin frustrar al usuario al abrir la pantalla.
- **Gestión del Foco y Usabilidad de Teclado:**
  - `FocusNode` vinculado a cada input con `TextInputAction.next` y `TextInputAction.done` para guiar al usuario por los campos sin obligarlo a tocar la pantalla continuamente.
  - Desplazamiento automático al campo con error mediante scroll seguro (`SingleChildScrollView`).

### 3.3 Validación de Inputs, Tipos de Datos y Seguridad
- **Sanitización y Tipado Fuerte:**
  - Validación de correos electrónicos con expresiones regulares conformes a RFC 5322.
  - Saneamiento de textos con `trim()` para eliminar espacios invisibles al inicio y final.
  - Control estricto de longitudes mínimas y máximas (`maxLength: 100` en títulos, `maxLength: 2000` en descripciones).
- **Protección contra Inyecciones:**
  - Prevención de scripts o caracteres de control maliciosos en inputs de texto.
  - Sanitización en cliente y validación innegociable en backend (.NET) con queries parametrizadas en Entity Framework Core.
- **Teclados Contextuales:**
  - `TextInputType.emailAddress` para correos, `TextInputType.phone` para teléfonos, `TextInputType.multiline` para descripciones de incidencias.

### 3.4 Gestión de Permisos del Dispositivo (Runtime Permissions)
- **Principio de Mínimo Privilegio:**
  - La aplicación solo solicita ubicación (`Geolocator`) en el momento en que el usuario toca "Usar mi ubicación" o crea un reporte, jamás de forma sorpresiva al arrancar la app.
- **Manejo de Estados de Permiso:**
  - `LocationPermission.denied`: Explicar al usuario la razón por la que se requiere el permiso ("Rationale") y solicitarlo nuevamente.
  - `LocationPermission.deniedForever`: Mostrar diálogo explicativo con botón directo a `Geolocator.openAppSettings()`.
- **Degradación Elegante:**
  - Si el usuario rechaza compartir su ubicación GPS, la aplicación permite seleccionar manualmente la provincia y municipio desde un catálogo validado.

### 3.5 Pruebas de Flujos de Login y Registro
- **Validación de Credenciales:**
  - Validación de contraseña segura (mínimo 8 caracteres, al menos una letra mayúscula, una minúscula y un número).
  - Normalización de correo a minúsculas para evitar cuentas duplicadas por capitalización.
- **Prevención de Enumeración de Usuarios:**
  - Mensajes de error deliberadamente neutrales ("Credenciales incorrectas" o "No se pudo iniciar sesión con estos datos") tanto si el correo no existe como si la contraseña es errónea.
- **Protección contra Fuerza Bruta:**
  - Soporte para cabeceras HTTP 429 (`Too Many Requests`) con mensaje amigable al usuario indicándole que espere antes de reintentar.

### 3.6 Control de Sesión y Ciclo de Vida de Tokens
- **Arquitectura de Tokens Segura:**
  - `accessToken` (JWT de vida corta) y `refreshToken` (token opaco de vida prolongada).
- **Almacenamiento Cifrado:**
  - `FlutterSecureStorage` (Keystore / Keychain) cuando el usuario marca "Recordar sesión". Si no la marca, los tokens se conservan únicamente en memoria volátil (`_memorySession`).
- **Renovación Concurrente Compartida (Mutex/Single-flight):**
  - Implementación en `ApiClient`: si múltiples peticiones simultáneas reciben un código 401, se sincronizan sobre un único `Future<bool> _refreshing`. Al resolverse la renovación, todas las peticiones en cola se reintentan con el nuevo token sin forzar múltiples llamadas al backend ni provocar cierres de sesión accidentales.
- **Cierre de Sesión Resiliente:**
  - `logout()` elimina los tokens locales de inmediato, incluso si no hay conexión a internet para notificar al servidor, garantizando que el usuario quede desautenticado en el dispositivo.

### 3.7 Resiliencia ante Pérdida de Conexión (Offline State)
- **Manejo No Destructivo de Errores:**
  - Un corte de red o error de servidor no se interpreta jamás como una lista vacía; se preservan los datos en pantalla y se informa al usuario mediante banner o snackbar.
- **Patrón Outbox para Operaciones Críticas:**
  - Encolado local de reportes pendientes cuando no hay conectividad para sincronizarlos tan pronto se restablezca el servicio.
- **Reintentos con Backoff Exponencial:**
  - Prevención del problema de "Thundering Herd" (reintentos simultáneos que saturan el backend al restablecerse la red).

### 3.8 Notificaciones Push y Deep Linking (Rutas Seguras)
- **Recepción en Diferentes Estados del Ciclo de Vida:**
  - **Foreground:** Notificación in-app no invasiva (banner/snackbar) sin interrumpir la tarea activa del usuario.
  - **Background / Terminated:** Apertura de la aplicación a través de la notificación del sistema con resolución segura del payload.
- **Validación Estricta de Rutas (Evitar Open Redirects):**
  - El payload de la notificación solo debe admitir identificadores de entidad (ej. `{"type": "post_detail", "postId": "post-123"}`) y mapearse internamente a la ruta controlada `MaterialPageRoute(builder: (_) => PostDetailScreen(postId: id))`. Nunca permitir ejecutar URLs arbitrarias no sanitizadas.
- **Preservación del Back Stack:**
  - Al abrir un reporte directamente desde una notificación, presionar el botón "Atrás" debe navegar naturalmente a la pantalla principal (`HomeScreen`), no cerrar la app bruscamente.

### 3.9 Accesibilidad Visual: Contraste y Tamaño de Texto
- **Estándar WCAG 2.1 Nivel AA:**
  - Ratio de contraste mínimo de 4.5:1 para texto normal y 3:1 para texto grande o elementos gráficos esenciales.
  - Temas claro y oscuro contrastados (paleta Rosé Pine / Rosé Pine Dawn) validados con herramientas de contraste cromático.
- **Soporte de Dynamic Type y TextScaleFactor:**
  - Prevención de desbordamientos visuales (`RenderFlex overflow`) ante fuentes grandes configuradas por el usuario en el sistema operativo mediante el uso de `Expanded`, `Flexible`, `Wrap` y `TextOverflow.ellipsis`.

### 3.10 Medición de Comportamiento, Embudos y Detección de Errores
- **Navegación Trazable (NavigatorObserver):**
  - Registro de transiciones entre pantallas para construir el historial de navegación del usuario.
- **Breadcrumbs de Sesión (Migas de Pan):**
  - Registro de los últimos 20 eventos de usuario antes de un crash (ej. "Entró al mapa", "Filtró por Servicios Públicos", "Pulsó Confirmar"), facilitando la reproducción exacta de fallos en desarrollo.
- **Detección de Frustración del Usuario (Rage Taps):**
  - Monitoreo de toques repetitivos rápidos en un mismo elemento sin respuesta, señal de que la interfaz está bloqueada o es poco intuitiva.

### 3.11 Accesibilidad Universal (A11y / Screen Readers)
- **Áreas Táctiles Mínimas:**
  - Botones e íconos interactivos con un tamaño táctil mínimo de 48x48 dp (Material Design) para facilitar la pulsación en pantallas de cualquier tamaño y a personas con dificultades motoras.
- **Semántica para Lectores de Pantalla:**
  - Inclusión de widgets `Semantics(button: true, label: "...")` en avatares, tarjetas y controles personalizados para que TalkBack (Android) y VoiceOver (iOS) anuncien claramente la función de cada elemento.

### 3.12 Analítica Móvil Ética y Telemetría
- **Datos de Diagnóstico Agregados:**
  - Medición de pantallas más vistas, tasas de éxito en creación de reportes y tiempos de carga.
- **Anonimización Incondicional:**
  - Cero Información de Identificación Personal (PII) en los eventos de analítica: prohibido enviar contraseñas, correos, tokens o coordenadas de domicilios particulares en las propiedades del evento.
- **Mecanismo de Opt-Out:**
  - Respeto a las preferencias del usuario sobre telemetría y diagnóstico según las directrices de privacidad de la Unión Europea (GDPR) y California (CCPA).

### 3.13 Crash Reporting en Tiempo Real
- **Captura Global de Excepciones:**
  - Intercepción de errores del framework con `FlutterError.onError`.
  - Captura de excepciones asíncronas no controladas en el Isolate raíz con `PlatformDispatcher.instance.onError`.
- **Desofuscación de Trazas:**
  - Generación y custodia de archivos de símbolos (`mapping.txt` de ProGuard en Android, archivos `.dSYM` en iOS, y split debug info de Flutter) para disponer de líneas de código exactas en paneles de reporte (Sentry o Firebase Crashlytics).

### 3.14 Comprobación de Enlaces (Deep Links y URLs Externas)
- **Universal Links (iOS) y App Links (Android):**
  - Verificación de dominio mediante archivos `/.well-known/assetlinks.json` en Android y `/.well-known/apple-app-site-association` en iOS para que los enlaces `https://rdreporta.com/posts/...` se abran de forma segura en la aplicación oficial sin que apps maliciosas puedan interceptar el esquema.
- **Apertura Segura con url_launcher:**
  - Sanitización de URLs externas comprobando esquemas seguros (`https://`) y apertura con `LaunchMode.externalApplication` o WebView aislado con `JavaScriptMode.disabled` si no se requiere ejecución de scripts.

### 3.15 Cuellos de Botella y Optimización de Rendimiento
- **Tasa de Refresco Fluida (60 / 120 FPS):**
  - Reducción del trabajo computacional en el hilo de interfaz (UI thread). Operaciones pesadas de parseo JSON delegadas a `compute()` o isolates secundarios.
- **Optimización del Árbol de Widgets:**
  - Uso riguroso de constructores `const` para reutilizar instancias en memoria y evitar reconstrucciones superfluas.
  - Aislamiento de áreas con animaciones complejas usando `RepaintBoundary`.
- **Prevención de Fugas de Memoria (Memory Leaks):**
  - Desconexión obligatoria de `TextEditingController`, `TabController`, `StreamSubscription` y listeners en el método `dispose()` de los widgets con estado.
- **Gestión Eficiente de Imágenes:**
  - Uso de `CachedNetworkImage` con limitación de resolución en memoria (`memCacheWidth`, `memCacheHeight`) para evitar saturar la memoria RAM con fotografías de alta resolución tomadas con la cámara del dispositivo.

### 3.16 Seguridad de Datos Sensibles, Secretos y Criptografía
- **Almacenamiento Criptográfico Seguro:**
  - Claves criptográficas protegidas por hardware (Android Keystore / iOS Secure Enclave).
  - Descarte total de `SharedPreferences` o archivos de texto plano para credenciales o tokens.
- **Certificate Pinning (SSL Pinning):**
  - Validación del hash SHA-256 de la clave pública del servidor HTTPS para frustrar ataques de intermediario (MITM) causados por certificados de CA falsificados o proxies locales de intercepción (Burp Suite, Charles).

### 3.17 Privacidad de Datos y Transparencia (Data Governance)
- **Inventario de Datos Recogidos:**
  - **Ubicación Geográfica:** Coordenadas latitud/longitud exclusivamente asociadas a incidencias de la vía pública reportadas por el usuario; no se rastrea la ubicación en segundo plano.
  - **Fotografías:** Imágenes tomadas voluntariamente por el usuario para evidenciar una avería o problema comunitario.
  - **Credenciales y Perfil:** Correo electrónico, nombre de usuario y provincia/municipio seleccionados.
- **Tratamiento y Protección:**
  - Los datos se transmiten cifrados (HTTPS TLS 1.3) y se almacenan en bases de datos con control de acceso restringido por roles.
  - Supresión de metadatos EXIF sensibles antes del almacenamiento definitivo.
- **Derechos del Usuario:**
  - Posibilidad de editar perfil, revocar permisos desde el sistema operativo y solicitar el borrado completo de su cuenta y sus publicaciones.

### 3.18 Pantalla Inicial (Splash Screen y Arranque en Frío)
- **Eliminación del Parpadeo Blanco ("White Flash"):**
  - Configuración del tema nativo con splash drawable en Android (`launch_background.xml` y Android 12+ `SplashScreen API`) y LaunchScreen en iOS para que coincida exactamente con el fondo de la app antes de que arranque la máquina virtual de Dart.
- **Verificación Asíncrona Inmediata:**
  - Lectura ultrarrápida del token en `FlutterSecureStorage` (<150 ms) y redirección limpia:
    - Si existe token válido: pantalla principal (`HomeScreen`).
    - Si no existe: pantalla principal en modo invitado con invitación no intrusiva a iniciar sesión al intentar interactuar o crear reportes.

### 3.19 Compatibilidad con Versiones Antiguas (Legacy) y Futuras
- **Compatibilidad con Ecosistema Android:**
  - `minSdkVersion 21` (Android 5.0 Lollipop) o 24 (Android 7.0), garantizando compatibilidad con más del 95% de terminales en circulación.
  - `targetSdkVersion 34+` (Android 14/15) para cumplir con las exigencias regulatorias de Google Play Console.
- **Compatibilidad con Ecosistema iOS:**
  - `IPHONEOS_DEPLOYMENT_TARGET = 13.0` o superior, abarcando desde dispositivos iPhone antiguos (iPhone 6s/7/8) hasta los modelos más recientes.
- **Arquitectura de Binarios:**
  - Soporte exclusivo para arquitecturas de 64 bits (`arm64-v8a` en Android, `arm64` en iOS), optimizando rendimiento y consumo energético.
- **Verificación Condicional de APIs:**
  - Comprobación dinámica de versión de sistema operativo antes de invocar funciones modernas que no existen en versiones legacy.

---

## 4. Checklist de Ejecución y Auditoría Automatizada del Proyecto

Para auditar y validar la calidad del código, la compilación de todos los subsistemas y la ausencia de vulnerabilidades, ejecutar desde la raíz del proyecto:

```powershell
.\scripts\run_audit.ps1
```

### Resultados de la Auditoría en RDReporta:
1. **Compilación Backend (.NET 10):** Aprobada sin errores.
2. **Escaneo de Vulnerabilidades NuGet:** Aprobado (0 dependencias vulnerables).
3. **Pruebas Automatizadas Móvil (Flutter Test):** 21 pruebas unitarias y de interfaz superadas con éxito (0 fallos).
4. **Análisis Estático Móvil (Flutter Analyze):** Aprobado ("No issues found!").
5. **Compilación Panel Administrativo (React + Vite + TypeScript):** Aprobada con éxito.

**Estado del Sistema:** 100% de verificaciones aprobadas.
