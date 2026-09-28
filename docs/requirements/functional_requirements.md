# RDReporta - Requisitos Funcionales y No Funcionales

## 1. Visión y Objetivo
RDReporta es una plataforma ciudadana enfocada en República Dominicana que combina una red social de información comunitaria con un sistema de reportes geolocalizados.
Su principio clave: **sin comentarios directos ni mensajes privados**, focalizando la interacción en **reacciones, confirmaciones ciudadanas y visualización georreferenciada**.

---

## 2. Actores del Sistema

| Actor | Descripción | Permisos Clave |
|---|---|---|
| **Ciudadano** | Usuario general de la app móvil. | Crear reportes con fotos/GPS, reaccionar, confirmar incidencias, consultar mapa y feed, reportar contenido inapropiado. |
| **Moderador** | Responsable de la salud y veracidad del contenido. | Revisar reportes de abuso, ocultar/eliminar publicaciones falsas o que violen normas, sancionar usuarios. |
| **Administrador** | Administrador global de la plataforma. | Gestión de usuarios, moderadores, categorías maestras, estadísticas del sistema y configuración. |
| **Entidad / Institución** *(Fase posterior)* | Agentes municipales o de emergencias (ej. 9-1-1, DIGESETT, MOPC, Alcaldías). | Recibir incidencias asignadas, actualizar estado de atención, registrar evidencia de resolución. |

---

## 3. Requisitos Funcionales (RF)

### 3.1 Módulo de Autenticación y Cuentas
- **RF-01:** Registro de usuario mediante correo electrónico y contraseña.
- **RF-02:** Inicio de sesión con correo y contraseña, con soporte de JWT (Access Token + Refresh Token).
- **RF-03:** Autenticación federada mediante Google Sign-In y Apple ID.
- **RF-04:** Recuperación y restablecimiento seguro de contraseña mediante enlace/código temporal por correo.
- **RF-05:** Cierre de sesión y revocación segura de tokens activos.

### 3.2 Módulo de Perfil y Reputación
- **RF-06:** Perfil ciudadano con nombre de usuario, foto de avatar y provincia/municipio opcional.
- **RF-07:** Visualización de métricas de perfil: cantidad de reportes creados, confirmaciones recibidas y nivel de reputación.
- **RF-08:** Sistema de reputación por niveles (*Ciudadano*, *Colaborador*, *Colaborador Confiable*) calculado mediante algoritmo basado en confirmaciones positivas y ausencia de sanciones/denuncias válidas.
- **RF-09:** Sin sistema de seguidores para evitar sesgos de popularidad individual.

### 3.3 Módulo de Publicaciones e Incidencias
- **RF-10:** Creación de reportes con selección de categoría dinámica, descripción textual, fotografías (máximo 4) y coordenadas geográficas.
- **RF-11:** Captura de ubicación vía GPS del dispositivo o selección manual en mapa interactivo.
- **RF-12:** Almacenamiento geoespacial (Point en coordenadas WGS84 - EPSG:4326) con resolución de Municipio y Provincia de República Dominicana.
- **RF-13:** Subida y compresión segura de fotografías a almacenamiento de objetos (S3 o compatible).
- **RF-14:** Estados de publicación: *Activo*, *Resuelto*, *Oculto*, *En Revisión*, *Eliminado*.

### 3.4 Módulo de Feeds e Interacción
- **RF-15:** **Feed "Para Ti":** Algoritmo inicial basado en relevancia comunitaria, provincia de residencia y popularidad ponderada.
- **RF-16:** **Feed "Cerca de Mí":** Consulta espacial por radio de distancia (ej. 1 km, 5 km, 15 km) a partir de la coordenada del usuario.
- **RF-17:** **Feed "Recientes":** Listado cronológico inverso de reportes validados.
- **RF-18:** **Reacciones:** Catálogo cerrado de reacciones: *Me interesa*, *Importante*, *Impactante*, *Estoy aquí*. Un usuario puede reaccionar una sola vez por tipo o retirar su reacción.
- **RF-19:** **Confirmaciones ("Confirmo"):** Acción de alta relevancia para que ciudadanos que presencian el hecho verifiquen que la incidencia es real y actual.
- **RF-20:** Contador de visualizaciones únicas por reporte para métricas de impacto.

### 3.5 Módulo de Mapa Interactivo
- **RF-21:** Visualización de incidencias como marcadores/clusters en Google Maps.
- **RF-22:** Filtros en mapa por categoría (Accidentes, Tránsito, Inundaciones, Basura, etc.), rango de fechas y radio de cobertura.
- **RF-23:** Vista rápida en bottom-sheet al seleccionar un marcador con acceso al detalle completo.

### 3.6 Módulo "Popular esta Semana"
- **RF-24:** Sección destacada con cálculo ponderado de impacto: usuarios únicos, confirmaciones, reacciones y visualizaciones en los últimos 7 días.
- **RF-25:** Algoritmo resistente al spam o manipulación artificial de votos.

### 3.7 Módulo de Moderación y Denuncias
- **RF-26:** Denuncia de contenido por ciudadanos con motivos predefinidos: *Información falsa*, *Spam*, *Acoso*, *Datos personales*, *Violencia*, *Ubicación incorrecta*, *Duplicado*, *Otro*.
- **RF-27:** Cola de moderación para que el equipo revise denuncias y aplique acciones (advertencia, eliminación de post, suspensión temporal o bloqueo de cuenta).

### 3.8 Módulo de Notificaciones
- **RF-28:** Notificaciones push mediante Firebase Cloud Messaging (FCM) para incidentes críticos cercanos o cambios de estado en reportes propios.
- **RF-29:** Notificaciones in-app con marcado de lectura.

---

## 4. Requisitos No Funcionales (RNF)

- **RNF-01 (Rendimiento):** Las consultas espaciales en la base de datos deben responder en menos de 100 ms para radios de búsqueda típicos mediante índices espaciales GiST en PostGIS.
- **RNF-02 (Seguridad):** Todas las comunicaciones deben estar cifradas mediante HTTPS/TLS 1.3. Contraseñas protegidas mediante Argon2id o PBKDF2 (ASP.NET Core Identity).
- **RNF-03 (Privacidad):** No exponer la ubicación GPS en tiempo real de los usuarios; únicamente se expone la coordenada asignada explícitamente a un reporte público.
- **RNF-04 (Escalabilidad):** Arquitectura modular monolítica desacoplada, lista para extracción de microservicios o workers asíncronos en el futuro.
- **RNF-05 (Disponibilidad y Concurrencia):** Manejo de picos de lectura mediante paginación basada en cursor/claves y caché en consultas de catálogo y feed popular.
