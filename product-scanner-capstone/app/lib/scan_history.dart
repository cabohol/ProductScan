import 'package:flutter/material.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  int _selectedIndex = 0;

  // Sample dummy data
  final List<Map<String, dynamic>> _sampleScans = [
    {
      'product_name': 'Ring',
      'category': 'Ring',
      'authenticity': 'Authentic',
      'estimated_value': '₱25,000',
      'confidence': 95.5,
      'date': 'Feb 06, 2024 14:30',
    },
    {
      'product_name': 'Necklace',
      'category': 'Necklace',
      'authenticity': 'Authentic',
      'estimated_value': '₱85,000',
      'confidence': 92.3,
      'date': 'Feb 05, 2024 10:15',
    },
    {
      'product_name': 'Earrings',
      'category': 'Earrings',
      'authenticity': 'Authentic',
      'estimated_value': '₱15,000',
      'confidence': 88.7,
      'date': 'Feb 03, 2024 09:20',
    },
  ];

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScanDetailsSheet(scan),
    );
  }

Widget _buildScanDetailsSheet(Map<String, dynamic> scan) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.85,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
    ),
    child: Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        const Text(
          'Scan Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005461),
            fontFamily: 'Syne',
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0C7779), width: 3),
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

                // Product Information Section
                _buildInfoRow(
                    Icons.diamond_outlined, 'Product', scan['product_name']),
                const SizedBox(height: 15),
                _buildInfoRow(
                    Icons.category_outlined, 'Category', scan['category']),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.verified_outlined, 'Authenticity',
                    scan['authenticity']),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.attach_money, 'Est. Value',
                    scan['estimated_value']),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.analytics_outlined, 'Confidence',
                    '${scan['confidence']}%'),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.calendar_today, 'Scanned', scan['date']),

                const SizedBox(height: 30),

                // Nearby Stores Section Header
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: const Color(0xFF0C7779),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Nearby Jewelry Stores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005461),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Map Placeholder
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0C7779), width: 2),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Map placeholder background
                        Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map,
                                  size: 60,
                                  color: const Color(0xFF0C7779).withOpacity(0.3),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Map will be integrated here',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // View on Maps button overlay
                        Positioned(
                          bottom: 15,
                          right: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF14A9A8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Future: Open full map view
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'View Map',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sample store listings (will be replaced with actual data from Google Maps)
                _buildStoreCard('Jewelry Store 1', '0.5 km away'),
                const SizedBox(height: 10),
                _buildStoreCard('Jewelry Store 2', '1.2 km away'),
                const SizedBox(height: 10),
                _buildStoreCard('Jewelry Store 3', '1.8 km away'),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A9A8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Close',
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
      ],
    ),
  );
}

Widget _buildStoreCard(String name, String distance) {
  return Container(
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
                name,
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
                    distance,
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _sampleScans.length,
        itemBuilder: (context, index) {
          final scan = _sampleScans[index];
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
                          scan['product_name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005461),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan['category'],
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
                              color: scan['authenticity'] == 'Authentic'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan['authenticity'],
                              style: TextStyle(
                                fontSize: 13,
                                color: scan['authenticity'] == 'Authentic'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              scan['estimated_value'],
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
                          scan['date'],
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
