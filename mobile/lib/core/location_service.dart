import 'package:geolocator/geolocator.dart';

Future<Position> requestCurrentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Activa la ubicación de tu dispositivo.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception(
        'Permite el acceso a la ubicación para consultar incidencias cercanas.');
  }
  return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 20),
  ));
}
