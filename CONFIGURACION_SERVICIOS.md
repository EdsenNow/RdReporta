# Configuración de servicios móviles

La aplicación ya contiene los clientes de Google Sign-In, Apple Sign-In,
Firebase Cloud Messaging y Google Maps. Los secretos y archivos emitidos por
los proveedores no se guardan en Git.

## Firebase y Google Sign-In

1. Crear un proyecto en Firebase Console.
2. Registrar la aplicación Android con `com.rdreporta.app`.
3. Instalar FlutterFire CLI y ejecutar desde `mobile`:

   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Activar Google en Firebase Authentication.
5. Añadir las huellas SHA-1 y SHA-256 de las firmas debug y release.
6. Ejecutar Flutter con el Client ID web usado por el servidor:

   ```powershell
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=CLIENT_ID_WEB
   ```

`flutterfire configure` genera `firebase_options.dart` y los archivos nativos.
No deben copiarse identificadores inventados.

## Firebase Cloud Messaging

La aplicación solicita permiso y registra el token en
`POST /api/notifications/devices`. Para Android, el archivo
`google-services.json` se genera al configurar Firebase. En iOS se necesita
`GoogleService-Info.plist`, Push Notifications, Background Modes y una clave
APNs cargada en Firebase.

El backend ya conserva tokens por dispositivo. El envío remoto requiere una
cuenta de servicio de Firebase configurada en el servidor; nunca debe incluirse
el JSON privado dentro de la aplicación móvil.

## Google Maps

Activar Maps SDK for Android y Maps SDK for iOS en Google Cloud. Restringir cada
clave por aplicación y por API.

En `mobile/android/local.properties` añadir:

```properties
MAPS_API_KEY=clave_android_restringida
```

Para iOS, añadir la clave mediante una configuración privada de Xcode y llamar
a `GMSServices.provideAPIKey` desde `AppDelegate.swift`. La clave de iOS debe
estar restringida al Bundle ID definitivo.

## Apple Sign-In

Requiere una cuenta de Apple Developer, un App ID con la capacidad **Sign in
with Apple**, un Service ID para Android/web y la asociación correspondiente en
Firebase o en el servidor. Xcode debe tener añadida la capacidad
`com.apple.developer.applesignin`.

El servidor debe validar firma, emisor, audiencia y vencimiento de todos los
tokens Google/Apple antes de crear una sesión de RDReporta.
