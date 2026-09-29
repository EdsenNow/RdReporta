---
name: rdreporta-social-ui
description: Diseña o revisa interfaces de RDReporta en Flutter o React usando patrones de aplicaciones sociales y de moderación, conservando el sistema de color Rosé Pine y la identidad cívica del producto.
---

# RDReporta Social UI

Diseña RDReporta como una plataforma ciudadana centrada en contenido, ubicación, confianza y respuesta comunitaria. Conserva los flujos y contratos con la API existentes salvo que el usuario pida cambios funcionales.

## Dirección visual

- Usa Rosé Pine como sistema cromático: base `#191724`, surface `#1f1d2e`, overlay `#26233a`, text `#e0def4`, subtle `#908caa`, love `#eb6f92`, rose `#ebbcba`, pine `#31748f`, foam `#9ccfd8`, iris `#c4a7e7` y gold `#f6c177`.
- Prioriza fotografías, título, categoría, ubicación, estado y señales comunitarias de cada publicación.
- Usa jerarquía tipográfica clara, espacio generoso y superficies discretas. Evita llenar cada área con tarjetas idénticas.
- Toma patrones conocidos de feeds, perfiles y bandejas sociales sin copiar marcas, iconografía propietaria o composiciones exactas.
- Mantén el tono cívico y confiable. RDReporta no tiene comentarios ni mensajes directos.

## Panel web

- Trátalo como una consola de operaciones comunitarias, no como una colección de métricas.
- Mantén navegación persistente, filtros visibles y acciones de moderación cerca del contexto que las justifica.
- Presenta publicaciones como contenido social escaneable; muestra tablas solamente cuando la comparación entre columnas sea el objetivo principal.
- En moderación, facilita abrir la evidencia antes de ocultar o descartar una denuncia y distingue claramente acciones destructivas.
- Diseña primero para escritorio y adapta navegación, filtros y acciones a pantallas móviles sin perder funciones.

## Aplicación móvil

- Haz que feed, mapa, creación de reporte, detalle y perfil compartan componentes, espaciado y estados.
- Mantén `Confirmo` como señal principal de confianza. Reacciones, vistas y reputación son secundarias.
- Da prioridad a ubicación, tiempo, categoría y evidencia visual. Nunca sugieras rastreo de personas en vivo.

## Comprobación

Revisa contraste, foco de teclado, estados vacíos, carga, error, textos largos y anchos de 360, 768 y 1280 píxeles. Ejecuta los analizadores y compilaciones disponibles en el proyecto después de cada cambio sustancial.
