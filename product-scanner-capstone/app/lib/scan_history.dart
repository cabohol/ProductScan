import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/supabase_service.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _scanHistoryFuture;
  final SupabaseStoreService _storeService = SupabaseStoreService();

  @override
  void initState() {
    super.initState();
    _scanHistoryFuture = _storeService.getScanHistory(limit: 50);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/scan');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user_profile');
    }
  }

  void _showScanDetails(Map<String, dynamic> scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScanDetailsPage(scan: scan, storeService: _storeService),
      ),
    );
  }

  /// Format ISO date string to readable format
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: Container(
          height: 200,
          padding:
              const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF005461),
                Color(0xFF0C7779),
                Color(0xFF14A9A8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 22),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  Center(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'SCAN HISTORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Syne',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scanHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF14A9A8),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading scan history',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final scans = snapshot.data ?? [];

          if (scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.diamond_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scans yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              final productData =
                  scan['products'] as Map<String, dynamic>? ?? {};
              final yoloLabel =
                  productData['yolo_label']?.toString().toUpperCase() ??
                      'Unknown';
              final authenticity =
                  scan['authenticity']?.toString() ?? 'Pending';
              final estimatedValue =
                  scan['estimated_value']?.toString() ?? 'N/A';
              final confidence =
                  (scan['confidence'] as num?)?.toStringAsFixed(1) ?? 'N/A';
              final scanDate = _formatDate(scan['scan_date']?.toString());

              return GestureDetector(
                onTap: () => _showScanDetails(scan),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF14A9A8).withOpacity(0.1),
                        const Color(0xFF0C7779).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0C7779).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Image placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF0C7779),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.diamond,
                          size: 40,
                          color: const Color(0xFF0C7779).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yoloLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005461),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authenticity,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: authenticity == 'Authentic'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  authenticity,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: authenticity == 'Authentic'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  estimatedValue,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0C7779),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scanDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron icon
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF0C7779),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 85,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C7779),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                const SizedBox(width: 80),
                _buildNavItem(Icons.person_outline_rounded,
                    Icons.person_rounded, 'Profile', 2),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -14,
            child: Center(
              child: GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14A9A8), Color(0xFF0C7779)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C7779).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData iconInactive, IconData iconActive, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 85,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? iconActive : iconInactive,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detailed view page for a single scan with map and nearby stores
class ScanDetailsPage extends StatefulWidget {
  final Map<String, dynamic> scan;
  final SupabaseStoreService storeService;

  const ScanDetailsPage({
    required this.scan,
    required this.storeService,
    super.key,
  });

  @override
  State<ScanDetailsPage> createState() => _ScanDetailsPageState();
}

class _ScanDetailsPageState extends State<ScanDetailsPage> {
  GoogleMapController? _mapController;
  Position? _userLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _nearbyStores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    try {
      // Extract product data
      final productData =
          widget.scan['products'] as Map<String, dynamic>? ?? {};
      final yoloLabel =
          productData['yolo_label']?.toString().toLowerCase() ?? 'jewelry';

      // Get user location
      _userLocation = await _getCurrentLocation();

      if (_userLocation == null) {
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

      // Check if a store was saved for this scan
      final scanId = widget.scan['id'] as int?;
      final savedStoreName = widget.scan['saved_store_name'];

      if (scanId != null &&
          savedStoreName != null &&
          savedStoreName.isNotEmpty) {
        // Only show the saved store
        final savedStoreId = widget.scan['saved_store_id'];
        _nearbyStores = [
          {
            'id': savedStoreId,
            'store_name': savedStoreName,
            'latitude': 7.0700, // Placeholder - would need to fetch from DB
            'longitude': 125.6100,
            'distance_text': 'Saved Store',
          }
        ];
      } else {
        // Fetch all nearby stores
        _nearbyStores = await widget.storeService.getStoresWithProduct(
          yoloLabel,
          _userLocation!,
        );
      }

      _createMarkers();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error initializing map: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  void _createMarkers() {
    _markers.clear();

    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    for (int i = 0; i < _nearbyStores.length; i++) {
      final store = _nearbyStores[i];

      _markers.add(
        Marker(
          markerId: MarkerId('store_${store['id']}'),
          position: LatLng(store['latitude'], store['longitude']),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: store['store_name'],
            snippet: '${store['distance_text']} away',
          ),
          onTap: () => _showStoreDetails(store),
        ),
      );
    }
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
            Text(
              store['store_name'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005461),
              ),
            ),
            const SizedBox(height: 16),
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

    final url = widget.storeService.getDirectionsUrl(
      _userLocation!,
      store['latitude'],
      store['longitude'],
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract scan data
    final productData = widget.scan['products'] as Map<String, dynamic>? ?? {};
    final yoloLabel =
        productData['yolo_label']?.toString().toUpperCase() ?? 'Unknown';
    final category = productData['category']?.toString() ?? 'Unknown';
    final authenticity = widget.scan['authenticity']?.toString() ?? 'Pending';
    final estimatedValue = widget.scan['estimated_value']?.toString() ?? 'N/A';
    final confidence =
        (widget.scan['confidence'] as num?)?.toStringAsFixed(1) ?? 'N/A';
    final scanDate = _formatDate(widget.scan['scan_date']?.toString());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C7779),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF14A9A8)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Information Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image placeholder
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0C7779),
                              width: 3,
                            ),
                            color: Colors.grey[200],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.diamond,
                              size: 80,
                              color: const Color(0xFF0C7779).withOpacity(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Product Info
                        _buildInfoRow(
                            Icons.diamond_outlined, 'Product', yoloLabel),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.category_outlined, 'Category', category),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.verified_outlined, 'Authenticity',
                            authenticity),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.attach_money, 'Est. Value', estimatedValue),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.analytics_outlined, 'Confidence',
                            '$confidence%'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.calendar_today, 'Scanned', scanDate),
                      ],
                    ),
                  ),

                  // Nearby Stores Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.store,
                              color: Color(0xFF0C7779),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nearby Stores (${_nearbyStores.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005461),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Map
                        if (_nearbyStores.isNotEmpty && _userLocation != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF0C7779),
                                  width: 2,
                                ),
                              ),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    _userLocation!.latitude,
                                    _userLocation!.longitude,
                                  ),
                                  zoom: 13,
                                ),
                                markers: _markers,
                                myLocationEnabled: true,
                                mapType: MapType.normal,
                                zoomControlsEnabled: false,
                                compassEnabled: true,
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: Text(
                                _nearbyStores.isEmpty
                                    ? 'No stores found'
                                    : 'Loading map...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Store List
                        if (_nearbyStores.isNotEmpty)
                          ...List.generate(
                            _nearbyStores.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildStoreCard(_nearbyStores[index]),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No stores found nearby',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C7779).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C7779).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0C7779), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF005461),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(store['latitude'], store['longitude']),
          ),
        );
        _showStoreDetails(store);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C7779).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0C7779).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C7779).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.store,
                color: Color(0xFF0C7779),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['store_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF005461),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['distance_text'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.directions,
              color: const Color(0xFF0C7779),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
