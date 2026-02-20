import 'dart:async';
import 'package:dio/dio.dart';

/// Model for geocoding search result
class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      address: json['address']?['road'] ?? json['address']?['suburb'],
      city: json['address']?['city'] ?? json['address']?['town'],
      country: json['address']?['country'],
    );
  }
}

/// Service for geocoding using OpenStreetMap Nominatim
class GeocodingService {
  final Dio _dio;
  Timer? _debounceTimer;

  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'User-Agent': 'KathirApp/1.0', // Required by Nominatim
              },
            ));

  /// Search for places by query string
  /// Returns list of matching locations
  Future<List<GeocodingResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => GeocodingResult.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocode: Get address from coordinates
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data['display_name'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Debounced search - useful for search-as-you-type
  Future<List<GeocodingResult>> debouncedSearch(
    String query,
    Duration delay,
  ) async {
    final completer = Completer<List<GeocodingResult>>();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      final results = await searchPlaces(query);
      if (!completer.isCompleted) {
        completer.complete(results);
      }
    });

    return completer.future;
  }

  /// Cancel any pending debounced searches
  void cancelDebounce() {
    _debounceTimer?.cancel();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _dio.close();
  }
}
