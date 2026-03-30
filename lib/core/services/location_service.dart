import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class LocationService {
  LocationService._();

  static const String _prefsKeyGranted = 'location_granted';
  static const String _prefsKeyLat = 'location_last_lat';
  static const String _prefsKeyLng = 'location_last_lng';

  static final LocationService instance = LocationService._();

  Position? _cached;

  Future<bool> isReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    final perm = await Geolocator.checkPermission();
    final hasPermission = perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
    return hasPermission;
  }

  /// Pide permiso si hace falta y guarda una ubicación inicial.
  /// Devuelve null si el usuario no habilita GPS / permisos.
  Future<Position?> ensureReadyAndFetch() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _cached = pos;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyGranted, true);
    await prefs.setDouble(_prefsKeyLat, pos.latitude);
    await prefs.setDouble(_prefsKeyLng, pos.longitude);
    return pos;
  }

  /// Obtiene ubicación sin volver a pedir permisos (pero puede refrescar si ya está lista).
  Future<Position?> getLastKnownOrFetch() async {
    if (_cached != null) return _cached;

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_prefsKeyLat);
    final lng = prefs.getDouble(_prefsKeyLng);
    if (lat != null && lng != null) {
      _cached = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      // Intento refrescar en background si está listo
      if (await isReady()) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
          _cached = pos;
          await prefs.setDouble(_prefsKeyLat, pos.latitude);
          await prefs.setDouble(_prefsKeyLng, pos.longitude);
        } catch (_) {}
      }
      return _cached;
    }

    if (!await isReady()) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _cached = pos;
      await prefs.setDouble(_prefsKeyLat, pos.latitude);
      await prefs.setDouble(_prefsKeyLng, pos.longitude);
      return pos;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLocalFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyGranted);
    await prefs.remove(_prefsKeyLat);
    await prefs.remove(_prefsKeyLng);
    _cached = null;
  }
}

