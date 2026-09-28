# Auditoría y Buenas Prácticas - RDReporta

Este documento sirve como referencia rápida para la ejecución de auditorías de calidad de código, seguridad y rendimiento en **RDReporta**.

El informe detallado de la auditoría completa, análisis de vulnerabilidades mitigadas y arquitectura de seguridad se encuentra en:
📁 **[docs/AUDITORIA_Y_SEGURIDAD.md](docs/AUDITORIA_Y_SEGURIDAD.md)**

---

## 🚀 ¿Cómo Ejecutar la Auditoría Automatizada?

### Opción 1: Indicármelo en el Chat
Simplemente escribe:
> **"Ejecuta la auditoría"**  
> o  
> **"Realiza la auditoría de nuevo"**

Yo ejecutaré todas las fases de verificación y te mostraré el reporte con el estado de cada componente.

---

### Opción 2: Desde la Terminal PowerShell
Ejecuta el script automatizado desde la raíz del proyecto:

```powershell
.\scripts\run_audit.ps1
```

---

## 📋 Checklist de la Auditoría

El script verifica automáticamente los siguientes puntos:

1. **Backend (.NET 10):**
   - Compilación completa sin errores ni advertencias.
   - Escaneo de vulnerabilidades conocidas en dependencias NuGet (`dotnet list package --vulnerable`).
2. **Móvil (Flutter):**
   - Ejecución de pruebas de humo / widgets (`flutter test`).
   - Análisis estático de buenas prácticas y tipos (`flutter analyze`).
3. **Panel Administrativo (React + TypeScript):**
   - Verificación de tipos TypeScript (`tsc -b`).
   - Compilación empaquetada de producción con Vite (`vite build`).
4. **Seguridad y Git:**
   - Estado de limpieza de Git y verificación de exclusiones de archivos sensibles.
