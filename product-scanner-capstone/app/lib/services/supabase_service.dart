import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';

class SupabaseStoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get stores with REAL road distances using Google Directions API
  /// This uses Dijkstra's algorithm (implemented by Google)
  Future<List<Map<String, dynamic>>> getStoresWithProduct(
      String productType, Position userLocation) async {
    try {
      print('Searching for stores with product type: $productType');

      // Step 1: Get ALL stores
      final storesResponse = await _supabase
          .from('stores')
          .select('id, store_name, latitude, longitude, available_products');

      if (storesResponse.isEmpty) {
        print('No stores found in database');
        return [];
      }

      print('Retrieved ${(storesResponse as List).length} total stores');

      // Step 2: Filter stores that have the product
      List<Map<String, dynamic>> matchingStores = [];

      for (var store in storesResponse as List) {
        String? availableProducts =
            store['available_products']?.toString().toLowerCase();

        if (availableProducts != null &&
            availableProducts.contains(productType.toLowerCase())) {
          matchingStores.add(store);
          print('Store "${store['store_name']}" has $productType');
        }
      }

      if (matchingStores.isEmpty) {
        print('No stores found selling: $productType');
        return [];
      }

      print('Found ${matchingStores.length} stores with $productType');

      // Step 3: Calculate REAL road distances using Google Directions API
      // (Google uses optimized Dijkstra's/A* algorithms internally)
      List<Map<String, dynamic>> storesWithDistance = [];

      for (var store in matchingStores) {
        print('Getting route to ${store['store_name']}...');
        
        final routeData = await _getRealRouteDistance(
          userLocation.latitude,
          userLocation.longitude,
          store['latitude'],
          store['longitude'],
        );

        storesWithDistance.add({
          ...store,
          'distance': routeData['distance'], // in km
          'distance_text': routeData['distance_text'],
          'duration': routeData['duration'], // in minutes
          'duration_text': routeData['duration_text'],
          'route_available': routeData['route_available'],
        });

        print('  Distance: ${routeData['distance_text']}, '
              'Duration: ${routeData['duration_text']}');
      }

      // Step 4: Sort by actual road distance (shortest path first)
      storesWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Limit to nearest 10 stores
      if (storesWithDistance.length > 10) {
        storesWithDistance = storesWithDistance.sublist(0, 10);
        print('Limiting to nearest 10 stores');
      }

      print('Returning ${storesWithDistance.length} nearest stores');

      return storesWithDistance;
    } catch (e, stackTrace) {
      print('Error fetching stores: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get actual route distance using Google Directions API
  /// Google's routing engine uses Dijkstra's algorithm (or optimized variants)
  /// to find the shortest path through the road network
  Future<Map<String, dynamic>> _getRealRouteDistance(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) async {
    try {
      final apiKey = ApiConfig.googleMapsApiKey;
      
      if (apiKey.isEmpty) {
        print('Warning: Google Maps API key not configured');
        return _fallbackToStraightLine(fromLat, fromLon, toLat, toLon);
      }

      // Google Directions API endpoint
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$fromLat,$fromLon'
        '&destination=$toLat,$toLon'
        '&mode=driving'
        '&key=$apiKey'
      );

      print('Calling Google Directions API...');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('API request timed out');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final distanceMeters = leg['distance']['value'];
          final durationSeconds = leg['duration']['value'];

          return {
            'distance': distanceMeters / 1000.0, // Convert to km
            'distance_text': leg['distance']['text'],
            'duration': durationSeconds / 60.0, // Convert to minutes
            'duration_text': leg['duration']['text'],
            'route_available': true,
          };
        } else {
          print('Google API returned status: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
        }
      } else {
        print('Google API HTTP error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error calling Google Directions API: $e');
    }

    // Fallback to straight-line distance
    print('Falling back to straight-line distance');
    return _fallbackToStraightLine(fromLat, fromLon, toLat, toLon);
  }

  /// Fallback: Calculate straight-line distance (Haversine formula)
  Map<String, dynamic> _fallbackToStraightLine(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    final distance = _calculateDistance(fromLat, fromLon, toLat, toLon);
    final estimatedDuration = (distance / 40) * 60; // Assume 40 km/h avg speed

    return {
      'distance': distance,
      'distance_text': _formatDistance(distance),
      'duration': estimatedDuration,
      'duration_text': _formatDuration(estimatedDuration),
      'route_available': false,
    };
  }

  /// Calculate straight-line distance using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} min';
    }
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '${hours}h ${mins}min';
  }

  String getDirectionsUrl(Position from, double toLat, double toLng) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${from.latitude},${from.longitude}'
        '&destination=$toLat,$toLng'
        '&travelmode=driving';
  }
  /// Save scan result to database with user_id (returns the scan record with ID)
  Future<Map<String, dynamic>?> saveScanResult({
    required String productName,
    required String category,
    required String yoloLabel,
    double? confidence,
    String? estimatedValue,
    String? authenticity,
    String? imagePath,
  }) async {
    try {
      print('Saving scan result to Supabase...');
      print('Product: $productName');
      print('Category: $category');
      print('YOLO Label: $yoloLabel');

      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user logged in!');
        return null;
      }
      print('User ID: $userId');

      // Step 1: Check if product already exists
      print('Querying products table for existing product...');
      Map<String, dynamic>? existingProduct;
      try {
        final resp = await _supabase
            .from('products')
            .select('id')
            .eq('yolo_label', yoloLabel)
            .maybeSingle();
        existingProduct = (resp as Map<String, dynamic>?);
        print('existingProduct response: $existingProduct');
      } catch (e) {
        print('existingProduct query error: ${e.runtimeType} - $e');
        try {
          print('details: ${(e as dynamic).details}');
          print('hint: ${(e as dynamic).hint}');
        } catch (_) {}
        return null;
      }

      int productId;

      if (existingProduct != null) {
        // Product exists, use existing ID
        productId = existingProduct['id'];
        print('Product already exists with ID: $productId');
      } else {
        // Step 2: Insert new product
        print(
            'Creating new product... payload: {category: $category, yolo_label: $yoloLabel}');
        try {
          final newProductResp = await _supabase
              .from('products')
              .insert({
                'category': category,
                'yolo_label': yoloLabel,
              })
              .select()
              .single();

          final newProduct = (newProductResp as Map<String, dynamic>);
          productId = newProduct['id'];
          print('New product created with ID: $productId');
        } catch (e) {
          print('newProduct insert error: ${e.runtimeType} - $e');
          try {
            print('details: ${(e as dynamic).details}');
            print('hint: ${(e as dynamic).hint}');
          } catch (_) {}
          return null;
        }
      }

      // Step 3: Prepare scan data (and try to avoid duplicates)
      print('Preparing scan_history entry...');
      final nowIso = DateTime.now().toIso8601String();
      final scanData = {
        'product_id': productId,
        'user_id': userId,
        'confidence': confidence ?? 0.0,
        'estimated_value': estimatedValue ?? 'N/A',
        'authenticity': authenticity ?? 'Pending',
        'image_path': imagePath,
        'scan_date': nowIso,
      };

      print('Scan data: $scanData');

      try {
        // DEDUPLICATION: check for an existing very recent scan for same user/product
        // We treat a scan as duplicate when the same user scanned the same product_id
        // within the last 30 seconds OR when the exact image_path already exists.
        final thirtySecondsAgo = DateTime.now()
            .subtract(const Duration(seconds: 30))
            .toIso8601String();

        final existing = await _supabase
            .from('scan_history')
            .select('id, scan_date, image_path')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .or("scan_date.gte.$thirtySecondsAgo,image_path.eq.${imagePath ?? ''}")
            .limit(1)
            .maybeSingle();

        if (existing != null) {
          print(
              'Duplicate scan detected — returning existing record: $existing');
          return (existing as Map<String, dynamic>);
        }

        final scanResp = await _supabase
            .from('scan_history')
            .insert(scanData)
            .select()
            .single();

        print('scan_history insert response: $scanResp');
        print('Scan saved successfully!');
        return (scanResp as Map<String, dynamic>);
      } catch (e) {
        print('scan_history insert error: ${e.runtimeType} - $e');
        try {
          print('details: ${(e as dynamic).details}');
          print('hint: ${(e as dynamic).hint}');
        } catch (_) {}
        return null;
      }
    } catch (e, stackTrace) {
      print('Error saving scan: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Save selected store for a scan
  Future<bool> saveSelectedStore({
    required int scanId,
    required int storeId,
    required String storeName,
  }) async {
    try {
      print('Saving selected store for scan...');
      print('Scan ID: $scanId, Store ID: $storeId, Store: $storeName');

      // Update scan_history with store_id and store_name
      await _supabase.from('scan_history').update({
        'saved_store_id': storeId,
        'saved_store_name': storeName,
      }).eq('id', scanId);

      print('Store saved successfully!');
      return true;
    } catch (e) {
      print('Error saving store: $e');
      return false;
    }
  }

  /// Get saved store for a specific scan
  Future<Map<String, dynamic>?> getSavedStoreForScan(int scanId) async {
    try {
      final response = await _supabase
          .from('scan_history')
          .select('saved_store_id, saved_store_name')
          .eq('id', scanId)
          .maybeSingle();

      if (response != null &&
          response['saved_store_id'] != null &&
          response['saved_store_id'] > 0) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting saved store: $e');
      return null;
    }
  }

  /// Get scan history for current user
  Future<List<Map<String, dynamic>>> getScanHistory({int limit = 20}) async {
    try {
      // Filter by current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return [];
      }

      final response = await _supabase
          .from('scan_history')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('scan_date', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching scan history: $e');
      return [];
    }
  }

  /// Get store details by store ID
  Future<Map<String, dynamic>?> getStoreById(int storeId) async {
    try {
      print('Fetching store details for ID: $storeId');

      final response = await _supabase
          .from('stores')
          .select('id, store_name, latitude, longitude, available_products')
          .eq('id', storeId)
          .maybeSingle();

      if (response != null) {
        print('Store found: ${response['store_name']}');
        return response as Map<String, dynamic>;
      }

      print('Store with ID $storeId not found');
      return null;
    } catch (e) {
      print('Error fetching store by ID: $e');
      return null;
    }
  }

  /// Delete a scan from scan_history by scan ID
  Future<bool> deleteScan(int scanId) async {
    try {
      print('Deleting scan with ID: $scanId');

      await _supabase.from('scan_history').delete().eq('id', scanId);

      print('Scan deleted successfully!');
      return true;
    } catch (e) {
      print('Error deleting scan: $e');
      return false;
    }
  }
}
