import 'dart:math';

double distanceKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = (pow(sin(dLat / 2), 2) +
          cos(_degToRad(lat1)) *
              cos(_degToRad(lat2)) *
              pow(sin(dLng / 2), 2))
      .toDouble();
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * pi / 180.0;
