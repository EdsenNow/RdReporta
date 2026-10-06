# RDReporta 🇩🇴

RDReporta es una plataforma ciudadana para registrar y consultar incidencias comunitarias en República Dominicana. Incluye una aplicación móvil, una API, un panel de moderación y soporte geoespacial.

## Descargar la aplicación

[![Descargar APK para Android](https://img.shields.io/badge/Descargar_APK-Android-2D957B?logo=android&logoColor=white)](https://github.com/EdsenNow/RdReporta/releases/latest)

La versión más reciente y sus notas están disponibles en [GitHub Releases](https://github.com/EdsenNow/RdReporta/releases).

> Android puede solicitar autorización para instalar aplicaciones provenientes del navegador o del explorador de archivos.

## Funciones principales

- Creación de reportes con ubicación, fotografías y videos.
- Mapa interactivo y consulta de incidencias cercanas.
- Perfiles, reacciones y actualización de actividad.
- Autenticación con correo, Google y Apple.
- Panel web para moderación y administración.
- Tema claro y oscuro.

## Estructura

```text
RdReporta/
├── mobile/      Aplicación Flutter
├── backend/     API ASP.NET Core
├── admin/       Panel React + TypeScript
├── database/    Inicialización de PostgreSQL/PostGIS
└── docker/      Entorno local con Docker Compose
```

## Configuración segura

- Usa los archivos `.example` únicamente como plantillas.
- Mantén contraseñas, tokens, claves privadas, credenciales de servicios y llaves de firma fuera de Git.
- Proporciona secretos mediante variables de entorno o el gestor de secretos de la plataforma de despliegue.
- Si una credencial llega a publicarse, revócala o rótala; eliminar el archivo del último commit no invalida el valor expuesto.
