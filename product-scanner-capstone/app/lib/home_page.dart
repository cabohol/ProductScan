import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final authService = AuthService();
  int _selectedIndex = 0; 

  final List<Map<String, String>> jewelryItems = [
    {'image': 'assets/images/j1.jpg', 'type': 'Ring'},
    {'image': 'assets/images/j2.jpg', 'type': 'Necklace'},
    {'image': 'assets/images/j3.jpg', 'type': 'Earrings'},
    {'image': 'assets/images/j4.jpg', 'type': 'Bracelet'},
  ];

  final List<Map<String, String>> jewelryTips = [
  {
    'title': 'Avoid Water & Chemicals',
    'description': 'Keep your jewelry away from water, perfumes, and cleaning chemicals to prevent tarnishing and damage.'
  },
  {
    'title': 'Store Properly',
    'description': 'Store jewelry in individual boxes or pouches to avoid scratches and tangles.'
  },
  {
    'title': 'Clean Regularly',
    'description': 'Use a soft cloth to gently clean your jewelry after wearing to maintain shine.'
  },
  {
    'title': 'Handle with Care',
    'description': 'Remove jewelry during physical activities or when sleeping to prevent bending or breakage.'
  },
];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Scan button
      Navigator.pushNamed(context, '/jewel_scan');
    } else if (index == 2) {
      // Profile button
      Navigator.pushNamed(context, '/user_profile');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final fullName = user?.userMetadata?['name'] as String? ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005461), Color(0xFF0C7779), Color(0xFF14A9A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 20),
                      Text(
                        'ProductScan',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Syne',
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: -70,
              bottom: -100,
              child: Image.asset(
                'assets/images/logo.png',
                height: 340,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0C7779), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C7779), Color(0xFF14A9A8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.diamond,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF005461),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Featured Jewelry Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Featured Collection',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005461),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Discover finest pieces',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14A9A8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF14A9A8),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Horizontal Jewelry Gallery
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: jewelryItems.length,
                  itemBuilder: (context, index) {
                    final item = jewelryItems[index];
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16, bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C7779),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Image
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.7),
                              builder: (BuildContext context) {
                                return BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                                            ),
                                            child: Image.asset(
                                              item['image']!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0C7779),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            height: 180,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0C7779),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Image.asset(
                                  item['image']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.diamond,
                                        size: 60,
                                        color: const Color(0xFF0C7779).withOpacity(0.3),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Info Container
                        Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center, 
                                child: Text(
                                  item['type']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005461),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.qr_code_scanner,
                            title: 'Scan Jewelry',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C7779), Color(0xFF14A9A8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => Navigator.pushNamed(context, '/jewel_scan'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.history,
                            title: 'Scan History',
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF005461),
                                const Color(0xFF0C7779).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Jewelry Care Tips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jewelry Care Tips',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005461),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: jewelryTips.length,
                      itemBuilder: (context, index) {
                        final tip = jewelryTips[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent, 
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0C7779), Color(0xFF14A9A8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          tip['title']!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Description
                                      Text(
                                        tip['description']!,
                                        textAlign: TextAlign.justify,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(0xFF0C7779),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text(
                                            'Close',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0C7779), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tip['title']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0C7779),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF0C7779),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

// Quick Action Card
Widget _buildQuickActionCard({
  required IconData icon,
  required String title,
  required Gradient gradient,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center, 
            ),
          ],
        ),
      ),
    ),
  );
}

  // Bottom Navigation Bar
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
                _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                const SizedBox(width: 80),
                _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 2),
              ],
            ),
          ),
          // Center Scan Button
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
                        boxShadow: [],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
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
                  boxShadow: [],
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