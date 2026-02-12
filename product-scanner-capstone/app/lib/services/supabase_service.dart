import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class SupabaseStoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get stores that have a specific product type (e.g., "ring", "necklace")
  Future<List<Map<String, dynamic>>> getStoresWithProduct(String productType, Position userLocation) async {
    try {
      // Step 1: Get products matching the yolo_label
      final productsResponse = await _supabase
          .from('products')
          .select('id')
          .eq('yolo_label', productType);

      if (productsResponse.isEmpty) {
        print('No products found for type: $productType');
        return [];
      }

      // Get product IDs
      final productIds = (productsResponse as List)
          .map((p) => p['id'] as int)
          .toList();

      // Step 2: Get store IDs that have these products
      final storeProductsResponse = await _supabase
          .from('store_products')
          .select('id')  // This should be the store's foreign key
          .inFilter('id', productIds);  // Adjust based on your actual FK column name

      if (storeProductsResponse.isEmpty) {
        print('No stores found with this product');
        return [];
      }

      final storeIds = (storeProductsResponse as List)
          .map((sp) => sp['id'] as int)  // Adjust field name
          .toSet()
          .toList();

      // Step 3: Get store details with locations
      final storesResponse = await _supabase
          .from('stores')
          .select('id, store_name, latitude, longitudede')  // Note: your DB has 'longitudede' typo
          .inFilter('id', storeIds);

      // Calculate distances and sort by nearest
      List<Map<String, dynamic>> storesWithDistance = [];
      
      for (var store in storesResponse as List) {
        double distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          store['latitude'],
          store['longitudede'],  // Your DB field name
        );

        storesWithDistance.add({
          ...store,
          'distance': distance,
          'distance_text': '${distance.toStringAsFixed(2)} km',
        });
      }

      // Sort by distance (nearest first)
      storesWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return storesWithDistance;

    } catch (e) {
      print('Error fetching stores: $e');
      return [];
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Get directions URL for Google Maps
  String getDirectionsUrl(Position from, double toLat, double toLng) {
    return 'https://www.google.com/maps/dir/?api=1&origin=${from.latitude},${from.longitude}&destination=$toLat,$toLng&travelmode=driving';
  }

  // Save scan result to database
  Future<bool> saveScanResult({
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
      
      // Step 1: Check if product already exists
      final existingProduct = await _supabase
          .from('products')
          .select('id')
          .eq('yolo_label', yoloLabel)
          .eq('product_name', productName)
          .maybeSingle();

      int productId;

      if (existingProduct != null) {
        // Product exists, use existing ID
        productId = existingProduct['id'];
        print('✅ Product already exists with ID: $productId');
      } else {
        // Step 2: Insert new product
        final newProduct = await _supabase
            .from('products')
            .insert({
              'product_name': productName,
              'category': category,
              'yolo_label': yoloLabel,
            })
            .select()
            .single();
        
        productId = newProduct['id'];
        print('✅ New product created with ID: $productId');
      }

      // Step 3: Save to scan_history
      await _supabase.from('scan_history').insert({
        'product_id': productId,
        'confidence': confidence ?? 0.0,
        'estimated_value': estimatedValue ?? 'N/A',
        'authenticity': authenticity ?? 'Pending',
        'image_path': imagePath,
        'scan_date': DateTime.now().toIso8601String(),
      });

      print('✅ Scan saved successfully!');
      return true;

    } catch (e) {
      print('❌ Error saving scan: $e');
      return false;
    }
  }

  // Get scan history (optional - for viewing past scans)
  Future<List<Map<String, dynamic>>> getScanHistory({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('scan_history')
          .select('*, products(*)')
          .order('scan_date', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching scan history: $e');
      return [];
    }
  }
}