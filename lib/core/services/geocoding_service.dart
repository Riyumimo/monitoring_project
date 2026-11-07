import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;

/// Latitude and longitude resolved from a free-text address.
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates(this.latitude, this.longitude);
}

/// A user-facing geocoding failure. The message is safe to show in a SnackBar.
class GeocodingException implements Exception {
  final String message;

  const GeocodingException(this.message);

  @override
  String toString() => message;
}

/// Resolves a free-text address into coordinates.
///
/// The `geocoding` plugin uses the native geocoder on Android, iOS and macOS.
/// It has no web implementation, so on web the lookup falls back to
/// OpenStreetMap's Nominatim service.
class GeocodingService {
  GeocodingService._();

  static Future<GeoCoordinates> coordinatesFromAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      throw const GeocodingException(
        'Enter an address before searching for coordinates.',
      );
    }

    try {
      return kIsWeb
          ? await _coordinatesFromNominatim(query)
          : await _coordinatesFromNativeGeocoder(query);
    } on GeocodingException {
      rethrow;
    } catch (_) {
      throw const GeocodingException(
        'Could not look up that address. Check the address and your '
        'connection, then try again.',
      );
    }
  }

  static Future<GeoCoordinates> _coordinatesFromNativeGeocoder(
    String address,
  ) async {
    final locations = await geocoding.Geocoding().locationFromAddress(address);
    if (locations.isEmpty) {
      throw const GeocodingException(
        'No coordinates were found for that address.',
      );
    }

    final location = locations.first;
    return GeoCoordinates(location.latitude, location.longitude);
  }

  static Future<GeoCoordinates> _coordinatesFromNominatim(
    String address,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'jsonv2',
      'limit': '1',
    });

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw const GeocodingException(
        'The address lookup service is unavailable. Please try again shortly.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! List || body.isEmpty) {
      throw const GeocodingException(
        'No coordinates were found for that address.',
      );
    }

    final first = body.first;
    final latitude = first is Map ? double.tryParse('${first['lat']}') : null;
    final longitude = first is Map ? double.tryParse('${first['lon']}') : null;
    if (latitude == null || longitude == null) {
      throw const GeocodingException(
        'The address lookup returned an unexpected result. Please try again.',
      );
    }

    return GeoCoordinates(latitude, longitude);
  }
}
