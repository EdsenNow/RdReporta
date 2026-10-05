# Archivos sin uso y candidatos a limpieza

Revisión: 1 de octubre de 2026. La identificación inicial no eliminó archivos; posteriormente el usuario autorizó la limpieza descrita a continuación.

## Limpieza aplicada

- Se retiraron los tres archivos Dart sin referencias, App.css, los dos SVG de assets, el sprite público icons.svg y el archivo HTTP de plantilla.
- Se archivaron los tres scripts build-*.js y los cinco scripts SQL manuales de la raíz.
- Se archivaron juntos PostTimestamp y su prueba, sin cambiar la presentación actual de las fechas.
- Se reemplazaron los README de plantilla del administrador y del móvil por instrucciones del proyecto.
- Antes de retirar archivos se creó `maintenance/archive/cleanup-2026-10-01.zip`: 20 entradas, incluidas las versiones anteriores de ambos README. Se verificó por SHA-256 cada entrada contra su archivo original. El respaldo es local y está excluido de Git; puede contener datos administrativos y no debe publicarse.
- Se quitaron flutter_bloc y cupertino_icons del manifiesto. `flutter pub get --offline` actualizó el bloqueo y retiró también bloc, nested y provider, que solo eran dependencias transitivas de los paquetes eliminados.
- Se conservaron cachés, compilaciones, evidencias de auditoría, plataformas y configuración del IDE. No se necesitaba recuperar espacio ni reconstruir el APK para esta limpieza.

Las tablas siguientes documentan los hallazgos iniciales; las rutas retiradas ya no se encuentran en sus ubicaciones originales.

### Comprobaciones posteriores

- `flutter analyze --no-pub`: sin problemas.
- Búsqueda de referencias a los archivos retirados en mobile/lib, mobile/test, admin/src y admin/index.html: sin coincidencias.
- Respaldo ZIP: 20 entradas verificadas por SHA-256 antes de retirar los originales; Git confirma que el ZIP está ignorado.
- CodeGraph: índice sincronizado después de retirar los archivos.
- `git diff --check` de los cambios de esta limpieza: sin errores de espacios; Git informó únicamente conversiones habituales LF/CRLF.
- `npm run build`: no se pudo completar. TypeScript informa errores en archivos que no se modificaron en esta limpieza: expresiones inválidas y parámetro no utilizado en ThemeSelector.tsx, importaciones que requieren `import type` en layouts/páginas y FormEvent sin uso en Posts.tsx. No se confirma una compilación correcta del administrador y no se ampliaron los cambios a esos archivos.
- No se ejecutaron pruebas, no se recompiló ni reinstaló el APK y no se borraron datos de usuarios.

## Alcance y método

Se consultó CodeGraph, se inventariaron archivos y se cruzaron importaciones, referencias de código, manifiestos, Docker y scripts. Se recorrieron las dependencias desde `mobile/lib/main.dart` y `admin/src/main.tsx`: 31 de 35 archivos Dart y 16 de 19 archivos de código/estilos/recursos del administrador resultaron alcanzables. Se comprobaron aparte las referencias desde pruebas. Los tamaños son aproximados y corresponden al disco durante la revisión.

Es una revisión estática: ausencia de referencias no demuestra que un script manual, documento o recurso público carezca de utilidad. No se ejecutaron pruebas ni compilaciones. No se clasificaron como archivos sobrantes las dependencias internas de paquetes instalados ni los archivos generados de plataformas.

## 1. Código y recursos sin referencias actuales

| Archivo | Evidencia y recomendación |
| --- | --- |
| `mobile/lib/features/auth/register_screen.dart` | No tiene importaciones ni referencias externas a `RegisterScreen`. Solo envuelve `LoginScreen(initialView: AuthView.register)`; el registro se maneja dentro de LoginScreen. Candidato a eliminación. |
| `mobile/lib/features/auth/forgot_password_screen.dart` | Sin importaciones ni referencias externas a `ForgotPasswordScreen`. Es otro envoltorio; LoginScreen maneja la recuperación. Candidato a eliminación. |
| `mobile/lib/shared/widgets/full_screen_gallery_viewer.dart` | Sin importaciones ni llamadas externas a `FullScreenGalleryViewer`. La aplicación usa el carrusel multimedia. Candidato a eliminación. |
| `admin/src/App.css` | No está importado desde la entrada ni desde otros archivos del administrador. El estilo conectado es `admin/src/index.css`. Candidato a eliminación; contiene cambios locales que conviene revisar antes. |
| `admin/src/assets/react.svg` | Sin referencias en código o HTML. Recurso de plantilla. |
| `admin/src/assets/vite.svg` | Sin referencias en código o HTML. Recurso de plantilla. |
| `admin/public/icons.svg` | Sin referencias en código o HTML. Sprite de plantilla. Vite publica recursos de `public` aunque no estén importados: confirmar que nadie lo consume mediante una URL externa antes de eliminarlo. |

### Componente desconectado que merece conservarse hasta decidir

`mobile/lib/shared/widgets/post_timestamp.dart` no es alcanzable desde la aplicación, pero sí lo importa `mobile/test/post_timestamp_test.dart`. No debe borrarse solo el componente: rompería esa prueba. Conviene decidir si se vuelve a conectar al formato de fechas de los reportes o si se retiran ambos archivos. Esta revisión no cambia el comportamiento de fechas.

### Dependencias declaradas aparentemente sin uso

`flutter_bloc` y `cupertino_icons` están en `mobile/pubspec.yaml`, pero no hay importaciones de esos paquetes ni usos de `CupertinoIcons` en `mobile/lib` o `mobile/test`. Son candidatos a retirar del manifiesto y actualizar mediante Flutter el archivo de bloqueo. No borrar carpetas de paquetes manualmente. No se cambió ninguna dependencia.

## 2. Scripts manuales y restos de plantilla

| Archivos | Situación |
| --- | --- |
| `build-css.js`, `build-modal.js`, `build-refactor.js` | Scripts de modificación puntual que escriben archivos existentes del administrador. No forman parte de los scripts npm ni tienen referencias desde la configuración revisada. Se pueden archivar o eliminar si ya terminó esa intervención. No son necesarios para ejecutar ni compilar el panel. |
| `list_roles.sql`, `list_users.sql`, `verify_user.sql`, `promote.sql`, `set_pwd.sql` | Scripts manuales sin referencias desde la app, Docker o automatizaciones revisadas. No se cargan automáticamente. Conservar solo si se siguen usando para administración; preferible documentarlos y moverlos a una carpeta de mantenimiento. No se imprimió su contenido. |
| `backend/src/RdReporta.Api/RdReporta.Api.http` | Plantilla que apunta a `localhost:5027/weatherforecast`, no al flujo actual de la API. Se puede eliminar o reemplazar por ejemplos reales. |
| `admin/README.md`, `mobile/README.md` | Documentación genérica de las plantillas React/Vite y Flutter. No participa en la ejecución. Preferible sustituirla por instrucciones propias; se puede eliminar si el README principal cubre la información necesaria. |
| `mobile/rdreporta.iml` | Metadatos de IntelliJ/Android Studio; no necesarios para Flutter desde terminal. Candidato a limpieza si no se usa esa configuración del IDE. |

Los scripts manuales no son código muerto confirmado: pueden ejecutarse fuera del repositorio o desde terminal sin referencias internas.

## 3. Carpetas regenerables y resultados de trabajo

| Ruta | Tamaño aproximado | Condición para limpiar |
| --- | ---: | --- |
| `mobile/build/` | 2.337 GiB | Resultados de compilación. Incluye el APK local: habrá que compilarlo de nuevo para reinstalar. La app ya instalada en el teléfono permanece instalada. |
| `mobile/.dart_tool/` | 650.6 MiB | Caché y metadatos; regenerar con `flutter pub get` y la compilación. |
| `mobile/android/.gradle/` | 22.3 MiB | Caché local de Gradle; limpiar con compilaciones detenidas. |
| `admin/node_modules/` | 124.5 MiB | Paquetes instalados; regenerar con `npm ci`. Sin ellos no funciona el servidor de desarrollo hasta reinstalar. |
| `admin/dist/` | 0.3 MiB | Compilación del administrador; regenerar con `npm run build`. Conservar si se está sirviendo ese directorio. |
| `backend/**/bin/`, `backend/**/obj/` | 140.3 MiB en conjunto | Binarios y cachés; detener API/compilaciones y recompilar después. `dotnet run --no-build` necesita los binarios. |
| `artifacts/` | 44.4 MiB | Registros, capturas y perfiles temporales de navegador de revisiones. Guardar las evidencias que se quieran conservar; limpiar perfiles con el navegador correspondiente cerrado. |
| `wwwroot/` de la raíz | 0 MiB, sin archivos | Carpeta vacía durante esta revisión. No confundir con el `wwwroot` de la API; el servicio de almacenamiento también contempla un directorio relativo como fallback. |

Las cachés y compilaciones suman aproximadamente **3.25 GiB**; con los resultados de `artifacts`, aproximadamente **3.30 GiB**. Limpiarlas recupera disco, pero aumenta el trabajo de la próxima compilación. No es necesario borrarlas para reducir tokens: es mejor excluirlas de búsquedas y lecturas.

## 4. Conservar

- `backend/src/RdReporta.Api/wwwroot/uploads/`: aproximadamente 261 MiB de archivos multimedia de usuarios; son datos de ejecución, no caché descartable.
- `.data-protection-keys/` y cualquier carpeta equivalente de la API: claves persistentes. No eliminarlas como parte de una limpieza genérica.
- `docker/.env`, archivos de firma, configuración Firebase y secretos locales: configuración necesaria; no confundir archivos ignorados por Git con archivos sin uso.
- `database/scripts/`: montado directamente por Docker para inicializar PostgreSQL.
- `database/seeds/`: no hay ejecución automática de estos seeds en la configuración revisada; documentan categorías y geografía y pueden utilizarse manualmente. No declararlos sobrantes.
- Los controladores C#: ASP.NET los descubre automáticamente, aunque su nombre no aparezca en llamadas explícitas. No se encontró un archivo C# claramente eliminable por falta de referencias.
- `mobile/assets/emojis/`: las seis imágenes están referenciadas por las reacciones; `assets/branding/google_g.png` está declarado en el manifiesto.
- `mobile/test/`, `backend/tests/`, `scripts/`, `.github/`: pruebas y herramientas de auditoría; no son necesarias en cada arranque, pero tienen utilidad y referencias.
- `.codegraph/`, `AGENTS.md`, `.codex/`, `.gemini/`, `GEMINI.md`: índice e instrucciones de asistentes. Solo prescindir de una integración si se deja de usar esa herramienta.
- `.git/`, manifiestos, archivos de bloqueo, configuración de compilación y documentación del proyecto.
- `mobile/android/` e `mobile/ios/`: soporte móvil. `mobile/windows/`, `mobile/linux/`, `mobile/macos/` y `mobile/web/` son soporte de otras plataformas; se pueden retirar únicamente si se decide abandonar esas plataformas. No son archivos muertos.

## Orden recomendado

1. Retirar los tres archivos Dart sin referencias y los recursos de plantilla confirmados, revisando los cambios locales de App.css.
2. Archivar los scripts puntuales que ya no se usan.
3. Decidir qué hacer con PostTimestamp y su prueba.
4. Retirar las dos dependencias aparentemente sin uso y actualizar el bloqueo mediante Flutter.
5. Limpiar cachés solo si hace falta espacio; mantenerlas fuera de consultas e índices que no las excluyan.

La limpieza autorizada se documenta al principio de este informe. Los elementos condicionales que no se retiraron requieren una decisión específica si se quiere continuar limpiando.
