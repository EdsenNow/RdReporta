# Aplicación móvil de RDReporta

Ejecuta desde mobile/ para instalar dependencias:

    flutter pub get
    flutter devices

## Teléfono Android por USB

Mantén Docker y la API ejecutándose en el PC. Sustituye el identificador si utilizas otro teléfono:

    & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F reverse tcp:5000 tcp:5000
    flutter run -d R5CR10FC10F --dart-define=API_BASE_URL=http://127.0.0.1:5000/api

Para abrir la app instalada sin compilar:

    & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F reverse tcp:5000 tcp:5000
    & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CR10FC10F shell am start -n com.rdreporta.app/.MainActivity

## Emulador Android

Enciende el emulador, consulta flutter devices y usa su identificador:

    flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000/api

La entrada es lib/main.dart. Consulta CONFIGURACION_SERVICIOS.md para Firebase, autenticación, mapas y producción.
