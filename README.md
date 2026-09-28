# RDReporta 🇩🇴

**RDReporta** es una plataforma móvil de información ciudadana y reportes geolocalizados para la República Dominicana. Permite a los ciudadanos publicar y consultar incidentes urbanos, accidentes, problemas viales y acontecimientos comunitarios en tiempo real, priorizando la veracidad a través de confirmaciones y reputación comunitaria, **sin mensajes directos ni comentarios**.

---

## 🚀 Arquitectura General

```text
RDReporta/
├── mobile/       # Aplicación móvil en Flutter (Dart) para Android e iOS
├── backend/      # API REST en ASP.NET Core (C#) con EF Core
├── admin/        # Panel administrativo y de moderación en React + TypeScript
├── database/     # Scripts SQL, migraciones y seeds geográficos (PostGIS)
├── docker/       # Entorno de contenedores local (PostgreSQL + PostGIS)
└── docs/         # Requisitos, especificaciones de API, arquitectura y diagramas
```

---

## 🛠️ Stack Tecnológico

- **Mobile:** Flutter (Dart) + Google Maps SDK + Firebase FCM.
- **Backend:** ASP.NET Core Web API (.NET) + Entity Framework Core + NetTopologySuite.
- **Base de Datos:** PostgreSQL con extensión espacial **PostGIS**.
- **Panel Administrativo:** React + TypeScript + Vite.
- **Infraestructura:** Docker / Docker Compose.
- **Almacenamiento de Fotos:** AWS S3 / Cloudflare R2 / MinIO compatible.
- **Autenticación:** JWT + Identity + Google Sign-In + Sign in with Apple.

---

## 🚦 Primeros Pasos

### 1. Requisitos Previos
- [.NET SDK](https://dotnet.microsoft.com/download) (versión 8 o superior).
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para PostgreSQL + PostGIS).
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (para el desarrollo móvil).
- [Node.js](https://nodejs.org/) (versión 20+ para el panel administrativo).

### 2. Iniciar la Base de Datos con PostGIS
```bash
cd docker
docker compose up -d
```
Esto iniciará un contenedor PostgreSQL en el puerto `5432` con la extensión PostGIS y las bases de datos preparadas.

---

## 📖 Documentación

Encuentra toda la documentación técnica detallada en la carpeta `docs/`:
- [Requisitos Funcionales y No Funcionales](docs/requirements/functional_requirements.md)
- [Arquitectura del Sistema](docs/architecture/system_overview.md)
- [Modelo de Datos Relacional y Espacial](docs/database/data_model.md)
- [Especificación de Endpoints REST API](docs/api/endpoints_spec.md)

---

## 🔒 Principios de Interacción
1. **Sin mensajes privados ni comentarios:** Foco total en hechos verídicos y mitigación de hostigamiento.
2. **Confirmaciones ciudadanas ("Confirmo"):** Valida la persistencia o veracidad de una incidencia en la comunidad.
3. **Privacidad:** La ubicación exacta solo se publica como metadato del reporte, nunca como rastreo en vivo de personas.
