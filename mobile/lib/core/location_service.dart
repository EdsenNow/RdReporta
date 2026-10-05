import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

enum LocationSettingsAction { app, location }

class LocationRequestException implements Exception {
  const LocationRequestException(this.message, {this.settingsAction});
  final String message;
  final LocationSettingsAction? settingsAction;
  @override
  String toString() => message;
}

Future<Position> requestCurrentLocation() async {
  try {
    // A failed Google settings check does not necessarily mean GPS is off.
    var permission = await Geolocator.checkPermission().timeout(
      const Duration(seconds: 8),
    );
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(
        const Duration(seconds: 60),
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationRequestException(
        'Permite el acceso a la ubicación de RDReporta en los ajustes de la aplicación.',
        settingsAction: LocationSettingsAction.app,
      );
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw const LocationRequestException(
        'RDReporta necesita permiso para acceder a tu ubicación. Vuelve a intentarlo y permite el acceso.',
      );
    }
    return await _requestFreshPosition();
  } on LocationServiceDisabledException {
    throw const LocationRequestException(
      'Android no tiene disponible un proveedor de ubicación. Revisa los ajustes de ubicación y vuelve a intentarlo.',
      settingsAction: LocationSettingsAction.location,
    );
  } on PermissionDeniedException {
    throw const LocationRequestException(
      'RDReporta no tiene permiso para acceder a tu ubicación. Revisa los permisos de la aplicación.',
      settingsAction: LocationSettingsAction.app,
    );
  } on TimeoutException {
    throw const LocationRequestException(
      'No se pudo obtener tu ubicación a tiempo. Si ya está activada, busca un lugar con mejor señal y vuelve a intentarlo.',
    );
  } on PlatformException {
    throw const LocationRequestException(
      'El servicio de ubicación no respondió correctamente. Vuelve a intentarlo.',
    );
  }
}

Future<Position> _requestFreshPosition() async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  } catch (error) {
    final canRetry = error is LocationServiceDisabledException ||
        error is TimeoutException ||
        error is PlatformException;
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !canRetry) {
      rethrow;
    }
    // The plugin cancels the first request at its time limit. Retry with
    // Android's provider without using a stale last-known position.
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        forceLocationManager: true,
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      ),
    );
  }
}
