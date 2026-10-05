# Instrucciones del proyecto

## Alcance y contexto
- Completa la petición y sus dependencias necesarias. Evita mejoras, auditorías o refactorizaciones ajenas a la tarea.
- Reutiliza el contexto comprobado. Relee solo si el archivo cambió, hay contradicciones o falta información.
- Mantén un resumen breve del objetivo, decisiones, archivos modificados y pendientes al continuar tareas largas.
- Conserva cambios locales ajenos y secretos. No borres ni publiques sin autorización.

<!-- CODEGRAPH_START -->
## CodeGraph
- Si existe .codegraph/, usa CodeGraph primero para localizar o entender código. No hace falta consultarlo para leer un documento nombrado, editar instrucciones o ejecutar un comando conocido.
- Prefiere codegraph_explore si está disponible. En CLI: codegraph explore --max-files 1 "archivo o símbolo concreto". Amplía solo si faltan dependencias.
- El código actual devuelto ya está leído: no lo vuelvas a cargar.
- Si el índice está desactualizado, ejecuta codegraph sync --quiet una vez; después usa fragmentos directos si sigue faltando código. No repitas consultas fallidas ni reconstruyas todo el índice sin necesidad.
<!-- CODEGRAPH_END -->

## Lecturas y herramientas
- Busca con rg en rutas concretas; usa rg -l para localizar archivos y rg -n para líneas. Lee fragmentos antes de archivos completos.
- Excluye .git, node_modules, build, dist, bin, obj, .dart_tool, .gradle, uploads y maintenance/archive, salvo que sean el objeto de la tarea.
- Limita las salidas de herramientas; empieza alrededor de 1500 tokens y amplía si hace falta. Filtra antes de imprimir; no vuelques registros, listados, JSON ni diffs completos.
- Agrupa operaciones independientes; mantén secuenciales las que dependan de resultados anteriores.
- Reutiliza procesos activos. Para compilaciones largas, espera 20–30 segundos entre consultas; informa cambios relevantes.
- Abre la app instalada con ADB. Compila e instala cuando sea necesario por cambios o por petición.

## Comprobación y respuestas
- Comprueba solo lo afectado. Para documentación, revisa contenido, referencias y diff; no compiles.
- No añadas ni ejecutes pruebas sin petición explícita. Ejecuta análisis o compilaciones cuando correspondan al cambio y evita repetirlos sin cambios.
- Distingue lo implementado, lo comprobado y lo pendiente. Informa errores ajenos sin ampliar automáticamente el alcance.
- Responde brevemente: resultado, comprobación y limitaciones relevantes. No repitas contexto, planes ni salidas ya mostradas.
