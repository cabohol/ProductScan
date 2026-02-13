import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class SupabaseStoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get stores that have a specific product type using available_products field
  /// This searches stores based on YOLO label (ring, necklace, earrings)
  /// and returns them sorted by distance from user (Dijkstra-like nearest-first)
  Future<List<Map<String, dynamic>>> getStoresWithProduct(
      String productType, Position userLocation) async {
    try {
      print('🔍 Searching for stores with product type: $productType');

      // Step 1: Get ALL stores with their available_products field
      final storesResponse = await _supabase
          .from('stores')
          .select('id, store_name, latitude, longitude, available_products');

      if (storesResponse.isEmpty) {
        print('⚠️ No stores found in database');
        return [];
      }

      print('📍 Retrieved ${(storesResponse as List).length} total stores');

      // Step 2: Filter stores that have the product type in available_products
      // The available_products field should contain comma-separated values like:
      // "ring, necklace, earrings" or just "ring"
      List<Map<String, dynamic>> matchingStores = [];

      for (var store in storesResponse as List) {
        String? availableProducts =
            store['available_products']?.toString().toLowerCase();

        // Check if the product type exists in available_products
        if (availableProducts != null &&
            availableProducts.contains(productType.toLowerCase())) {
          matchingStores.add(store);
          print('✅ Store "${store['store_name']}" has $productType');
        }
      }

      if (matchingStores.isEmpty) {
        print('⚠️ No stores found selling: $productType');
        return [];
      }

      print('✅ Found ${matchingStores.length} stores with $productType');

      // Step 3: Calculate distances using Haversine formula (great-circle distance)
      List<Map<String, dynamic>> storesWithDistance = [];

      for (var store in matchingStores) {
        double distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          store['latitude'],
          store['longitude'],
        );

        storesWithDistance.add({
          ...store,
          'distance': distance,
          'distance_text': _formatDistance(distance),
        });
      }

      // Step 4: Sort by distance (Dijkstra-like nearest-first approach)
      // This gives us the shortest path/distance from user to each store
      storesWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Optional: Limit to nearest 10 stores to avoid overwhelming the user
      if (storesWithDistance.length > 10) {
        storesWithDistance = storesWithDistance.sublist(0, 10);
        print('📊 Limiting to nearest 10 stores');
      }

      print('✅ Returning ${storesWithDistance.length} nearest stores');

      // Print the nearest stores for debugging
      for (var i = 0; i < storesWithDistance.length; i++) {
        print(
            '  ${i + 1}. ${storesWithDistance[i]['store_name']} - ${storesWithDistance[i]['distance_text']}');
      }

      return storesWithDistance;
    } catch (e, stackTrace) {
      print('❌ Error fetching stores: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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

  /// Convert degrees to radians
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Format distance for display
  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      // Show in meters if less than 1 km
      return '${(distanceKm * 1000).round()} m';
    } else {
      // Show in km with 2 decimal places
      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  /// Get directions URL for Google Maps
  String getDirectionsUrl(Position from, double toLat, double toLng) {
    return 'https://www.google.com/maps/dir/?api=1&origin=${from.latitude},${from.longitude}&destination=$toLat,$toLng&travelmode=driving';
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
      print('💾 Saving scan result to Supabase...');
      print('📝 Product: $productName');
      print('📝 Category: $category');
      print('📝 YOLO Label: $yoloLabel');

      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ Error: No user logged in!');
        return null;
      }
      print('👤 User ID: $userId');

      // Step 1: Check if product already exists
      print('🔎 Querying products table for existing product...');
      Map<String, dynamic>? existingProduct;
      try {
        final resp = await _supabase
            .from('products')
            .select('id')
            .eq('yolo_label', yoloLabel)
            .maybeSingle();
        existingProduct = (resp as Map<String, dynamic>?);
        print('🔁 existingProduct response: $existingProduct');
      } catch (e) {
        print('❌ existingProduct query error: ${e.runtimeType} - $e');
        try {
          print('❌ details: ${(e as dynamic).details}');
          print('❌ hint: ${(e as dynamic).hint}');
        } catch (_) {}
        return null;
      }

      int productId;

      if (existingProduct != null) {
        // Product exists, use existing ID
        productId = existingProduct['id'];
        print('✅ Product already exists with ID: $productId');
      } else {
        // Step 2: Insert new product
        print(
            '📝 Creating new product... payload: {category: $category, yolo_label: $yoloLabel}');
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
          print('✅ New product created with ID: $productId');
        } catch (e) {
          print('❌ newProduct insert error: ${e.runtimeType} - $e');
          try {
            print('❌ details: ${(e as dynamic).details}');
            print('❌ hint: ${(e as dynamic).hint}');
          } catch (_) {}
          return null;
        }
      }

      // Step 3: Save to scan_history with user_id
      print('💾 Saving to scan_history...');
      final scanData = {
        'product_id': productId,
        'user_id': userId,
        'confidence': confidence ?? 0.0,
        'estimated_value': estimatedValue ?? 'N/A',
        'authenticity': authenticity ?? 'Pending',
        'image_path': imagePath,
        'scan_date': DateTime.now().toIso8601String(),
      };

      print('📦 Scan data: $scanData');

      try {
        final scanResp = await _supabase
            .from('scan_history')
            .insert(scanData)
            .select()
            .single();
        print('🔁 scan_history insert response: $scanResp');
        print('✅ Scan saved successfully!');
        return (scanResp as Map<String, dynamic>);
      } catch (e) {
        print('❌ scan_history insert error: ${e.runtimeType} - $e');
        try {
          print('❌ details: ${(e as dynamic).details}');
          print('❌ hint: ${(e as dynamic).hint}');
        } catch (_) {}
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error saving scan: $e');
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
      print('💾 Saving selected store for scan...');
      print('📍 Scan ID: $scanId, Store ID: $storeId, Store: $storeName');

      // Update scan_history with store_id and store_name
      await _supabase.from('scan_history').update({
        'saved_store_id': storeId,
        'saved_store_name': storeName,
      }).eq('id', scanId);

      print('✅ Store saved successfully!');
      return true;
    } catch (e) {
      print('❌ Error saving store: $e');
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
      print('❌ Error getting saved store: $e');
      return null;
    }
  }

  /// Get scan history for current user
  Future<List<Map<String, dynamic>>> getScanHistory({int limit = 20}) async {
    try {
      // Filter by current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
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
      print('❌ Error fetching scan history: $e');
      return [];
    }
  }
}
