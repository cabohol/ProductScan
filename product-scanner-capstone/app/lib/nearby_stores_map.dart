import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class NearbyStoresMapPage extends StatefulWidget {
  final String productType; 
  final String productName;

  const NearbyStoresMapPage({
    super.key,
    required this.productType,
    required this.productName,
  });

  @override
  State<NearbyStoresMapPage> createState() => _NearbyStoresMapPageState();
}

class _NearbyStoresMapPageState extends State<NearbyStoresMapPage> {
  GoogleMapController? _mapController;
  Position? _userLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _nearbyStores = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final SupabaseStoreService _storeService = SupabaseStoreService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      print('🗺️ Initializing map...');
      
      // Get user location
      _userLocation = await _getCurrentLocation();
      
      if (_userLocation == null) {
        print('⚠️ Using default location (Davao City)');
        // Use default location if GPS fails (Davao City center)
        _userLocation = Position(
          latitude: 7.0700,
          longitude: 125.6100,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      print('📍 User location: ${_userLocation!.latitude}, ${_userLocation!.longitude}');

      // Fetch nearby stores
      print('🔍 Searching for stores with: ${widget.productType}');
      _nearbyStores = await _storeService.getStoresWithProduct(
        widget.productType,
        _userLocation!,
      );

      print('✅ Found ${_nearbyStores.length} stores');

      // Create markers
      _createMarkers();

      setState(() => _isLoading = false);

    } catch (e, stackTrace) {
      print('❌ Error initializing map: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showError('Failed to load map: $e');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      print('📱 Checking location permission...');
      
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('🔐 Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          _showError('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        _showError('Location permission permanently denied');
        return null;
      }

      print('✅ Permission granted, getting position...');
      
      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ Got position: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  void _createMarkers() {
    _markers.clear();
    print('📍 Creating ${_nearbyStores.length + 1} markers...');

    // Add user location marker (blue)
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      print('✅ Added user marker at ${_userLocation!.latitude}, ${_userLocation!.longitude}');
    }

    // Add store markers (green)
    for (int i = 0; i < _nearbyStores.length; i++) {
      final store = _nearbyStores[i];
      print('✅ Adding store marker: ${store['store_name']} at ${store['latitude']}, ${store['longitude']}');
      
      _markers.add(
        Marker(
          markerId: MarkerId('store_${store['id']}'),
          position: LatLng(store['latitude'], store['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: store['store_name'],
            snippet: '${store['distance_text']} away',
          ),
          onTap: () => _showStoreDetails(store),
        ),
      );
    }
    
    print('✅ Total markers created: ${_markers.length}');
  }

  void _showStoreDetails(Map<String, dynamic> store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Store name
            Text(
              store['store_name'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005461),
              ),
            ),
            const SizedBox(height: 16),

            // Distance
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF14A9A8)),
                const SizedBox(width: 8),
                Text(
                  store['distance_text'],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Directions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(store),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14A9A8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text(
                  'Get Directions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(Map<String, dynamic> store) async {
    if (_userLocation == null) return;

    final url = _storeService.getDirectionsUrl(
      _userLocation!,
      store['latitude'],
      store['longitude'],
    );

    print('🗺️ Opening directions: $url');

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open maps');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C7779),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearby Stores',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Selling ${widget.productName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF14A9A8),
                  ),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _nearbyStores.isEmpty
                  ? _buildNoStoresState()
                  : Stack(
                      children: [
                        // Map
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                            ),
                            zoom: 13,
                          ),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                          onMapCreated: (controller) {
                            print('✅ Map created successfully');
                            _mapController = controller;
                          },
                        ),

                        // Store list at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Stores Found (${_nearbyStores.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF005461),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _nearbyStores.length,
                                    itemBuilder: (context, index) {
                                      final store = _nearbyStores[index];
                                      return _buildStoreCard(store);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        // Move camera to store
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(store['latitude'], store['longitude']),
          ),
        );
        _showStoreDetails(store);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C7779).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF14A9A8),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              store['store_name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005461),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF14A9A8),
                ),
                const SizedBox(width: 4),
                Text(
                  store['distance_text'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF005461),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeMap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A9A8),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStoresState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No stores found nearby',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'with ${widget.productName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}