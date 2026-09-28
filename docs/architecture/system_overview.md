# RDReporta - Arquitectura del Sistema

## 1. Diagrama General de Arquitectura

```text
+-----------------------------------------------------------+
|                   APLICACIÓN MÓVIL (FLUTTER)              |
|                     (Android & iOS)                       |
+-----------------------------------------------------------+
        |                                       |
        | HTTPS / REST (JSON)                   | SDK Mapas
        v                                       v
+-------------------------------+       +-------------------+
|      ASP.NET CORE WEB API     |       | Google Maps API   |
|   (Arquitectura Limpia /      |       +-------------------+
|     Monolito Modular)         |
+-------------------------------+
   |             |            |
   | EF Core     | SDK S3     | Firebase Admin SDK
   v             v            v
+-----------+ +------------+ +----------------------+
|PostgreSQL | | S3 Storage | | Firebase Cloud       |
| + PostGIS | | (Imágenes) | | Messaging (Push)     |
+-----------+ +------------+ +----------------------+
```

---

## 2. Componentes del Ecosistema

### 2.1 Backend: ASP.NET Core Web API (C#)
- **Patrón:** Monolito Modular con principios de *Clean Architecture* (Domain, Application, Infrastructure, API).
- **Módulos:**
  - `Auth`: Autenticación local (Identity) y externa (Google, Apple), emisión de JWT.
  - `Users`: Perfiles, niveles de reputación, configuraciones de usuario.
  - `Posts`: Ciclo de vida del reporte, validación, búsqueda espacial.
  - `Reactions & Confirmations`: Contabilización eficiente y prevención de duplicados.
  - `Categories`: Catálogo configurable dinámicamente desde el backend.
  - `Locations`: Geocodificación inversa y normalización de provincias/municipios de RD.
  - `Moderation`: Reportes de abuso, auditoría y sanciones.
  - `Notifications`: Despacho de alertas push y almacenamiento in-app.

### 2.2 Base de Datos: PostgreSQL 16 + PostGIS 3.4
- **PostGIS:** Maneja tipos de datos espaciales (`geometry(Point, 4326)` o `geography(Point, 4326)`).
- **Índices Espaciales:** Índices `GIST` sobre las columnas de ubicación para optimizar operaciones `ST_DWithin` y `ST_Distance`.
- **Entity Framework Core:** `Npgsql.EntityFrameworkCore.PostgreSQL.NetTopologySuite` para mapear tipos espaciales en C#.

### 2.3 Aplicación Móvil: Flutter (Dart)
- **Estructura:** Arquitectura orientada a características (*Feature-First*):
  - `core/`: Networking (Dio/Retrofit o Http), Routing (GoRouter), Theme, LocalStorage, Errors.
  - `features/`: auth, feed, posts, map, popular, profile, notifications.
  - `shared/`: Componentes UI reutilizables, utilitarios comunes.
- **Gestión de Estado:** Bloc / Cubit o Riverpod para control predecible del flujo de datos.

### 2.4 Panel Administrativo: React + TypeScript
- Construido para el equipo de moderación y administración.
- Consumo de endpoints administrativos protegidos por roles (`Admin`, `Moderator`).

---

## 3. Estrategia de Almacenamiento de Medios
- Los clientes móviles no suben imágenes directamente a la base de datos ni saturan el servidor de API con bytes innecesarios.
- El backend puede generar **Presigned URLs** o procesar imágenes mediante streaming para validación de tipo MIME, tamaño y generación de thumbnails optimizados (WebP).

---

## 4. Estrategia de Caché y Escalabilidad
- **Paginación:** Todas las listas (Feed, Popular, Historial) utilizan paginación basada en cursor para evitar problemas de desplazamiento cuando se agregan nuevos registros.
- **Caché en Memoria / Redis:** Para categorías, configuraciones y listas de tendencias de corta duración.
