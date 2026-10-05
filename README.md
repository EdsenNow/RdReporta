# RDReporta 🇩🇴

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![.NET 10](https://img.shields.io/badge/.NET%2010-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![PostGIS](https://img.shields.io/badge/PostGIS-Spatial-green?style=for-the-badge)](https://postgis.net)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)

**RDReporta** es una plataforma ciudadana moderna diseñada para la República Dominicana que permite a los ciudadanos documentar, visualizar y reportar incidencias comunitarias, vialidad, emergencias y servicios públicos en tiempo real con geolocalización precisa.

---

## 📲 Descargar la Aplicación para Android

Puedes descargar e instalar la versión oficial directamente en tu teléfono Android:

[![Descargar APK](https://img.shields.io/badge/Descargar%20APK-Android%20Release-brightgreen?style=for-the-badge&logo=android)](https://github.com/EdsenNow/RdReporta/releases/latest)

> 💡 **¿Cómo instalar el APK?**
> 1. Haz clic en el botón de arriba o ve a la sección de [Releases oficiales](https://github.com/EdsenNow/RdReporta/releases).
> 2. Descarga el archivo `.apk` en tu dispositivo.
> 3. Ábrelo en tu teléfono y selecciona **"Instalar"** (si tu teléfono lo solicita, permite la instalación desde tu navegador o explorador de archivos).

---

## ✨ Características Principales

* 📍 **Geolocalización precisa:** Reportes ubicados en el mapa mediante coordenadas GPS y consultas espaciales de alto rendimiento con **PostGIS**.
* 📸 **Multimedia enriquecido:** Carga de fotografías y videos de denuncias ciudadanas.
* 🗺️ **Mapa interactivo:** Visualización de incidentes cercanos en Google Maps con diferenciación visual de reportes propios y comunitarios.
* 👁️ **Métricas en tiempo real:** Contadores de vistas y reacciones actualizados en vivo mediante Server-Sent Events (SSE).
* 🔐 **Autenticación segura:** Inicio de sesión rápido con Google Sign-In o mediante correo electrónico y contraseña.
* 🌓 **Diseño moderno:** Interfaz optimizada con modo oscuro y modo claro.
* 🛡️ **Panel administrativo:** Panel web para moderación de contenido, categorías, usuarios y seguimiento de incidencias.

---

## 🏗️ Arquitectura del Sistema

```text
RDReporta/
├── mobile/       # Aplicación móvil en Flutter (Android & iOS)
├── backend/      # API REST en ASP.NET Core (.NET 10)
├── admin/        # Panel de administración web (React + Vite + TypeScript)
├── database/     # Scripts SQL y esquemas de base de datos PostGIS
└── docker/       # Configuración de contenedores con Docker Compose
```

* **Frontend Móvil:** Flutter con arquitectura por capas (BLoC/Provider, Dio, Google Maps).
* **Backend API:** ASP.NET Core 10 Web API con Entity Framework Core, autenticación JWT y rate limiting.
* **Base de Datos:** PostgreSQL con extensión PostGIS para análisis geoespacial.
* **Contenedores:** Docker multi-etapa listo para despliegue en local o en la nube (Railway / Render / VPS).

---

## 🚀 Puesta en marcha para desarrollo

### 1. Clonar el repositorio
```bash
git clone https://github.com/EdsenNow/RdReporta.git
cd RdReporta
```

### 2. Iniciar la base de datos y la API con Docker
```bash
docker compose -f docker/docker-compose.yml up -d
```
Esto levantará:
* **PostgreSQL + PostGIS** en el puerto `5432`.
* **API .NET 10** en el puerto `5000` (con endpoints de salud en `/health` y documentación de API).

### 3. Ejecutar la aplicación móvil
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📄 Licencia

Este proyecto está distribuido bajo la licencia MIT. Consulta el archivo de licencia para más detalles.
