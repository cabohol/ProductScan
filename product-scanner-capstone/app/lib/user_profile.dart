import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final authService = AuthService();
  int _selectedIndex = 2;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isEditingAddress = false;
  String? _initialName;
  String? _initialAddress; 
  String? _avatarUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;
    _initialName = user?.userMetadata?['name'] as String? ?? '';
    _initialAddress = user?.userMetadata?['address'] as String? ?? ''; 
    _avatarUrl = authService.getProfilePictureUrl();
    _nameController = TextEditingController(text: _initialName);
    _addressController = TextEditingController(text: _initialAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose(); 
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/scan');
    } else if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    try {
      await authService.updateUserName(newName);
      setState(() {
        _isEditing = false;
        _initialName = newName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: const Color(0xFF249E94),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Name updated successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to update name: $e',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveAddress() async {
  final newAddress = _addressController.text.trim();
  if (newAddress.isEmpty) return;

  try {
    await authService.updateUserAddress(newAddress);
    setState(() {
      _isEditingAddress = false;
      _initialAddress = newAddress;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: const Color(0xFF249E94),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Address updated successfully!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to update address: $e',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoadingImage = true);

      // Read image as bytes
      final imageBytes = await image.readAsBytes();
      final String publicUrl = await authService.uploadProfilePicture(imageBytes, image.name);

      setState(() {
        _avatarUrl = publicUrl;
        _isLoadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: const Color(0xFF249E94),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Profile picture updated!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to upload image: $e',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      setState(() => _isLoadingImage = true);

      await authService.deleteProfilePicture();

      setState(() {
        _avatarUrl = null;
        _isLoadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: const Color(0xFF249E94),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Profile picture removed!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to delete image: $e',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0C7779)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0C7779)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final email = user?.email ?? '';

   return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(280),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF005461),
                    Color(0xFF0C7779),
                    Color(0xFF14A9A8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(70),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF249E94),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: _isLoadingImage
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : _avatarUrl == null
                              ? const Icon(Icons.person, size: 150, color: Colors.white)
                              : ClipOval(
                                  child: Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(color: Colors.white),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 150, color: Colors.white);
                                    },
                                  ),
                                ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImageOptions,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14A9A8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),

                      // Name Section
                      Text('Name', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _isEditing
                                ? TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Color(0xFF0C7779), size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        _initialName ?? '',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF005461)),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          _isEditing
                              ? ElevatedButton.icon(
                                  onPressed: _saveName,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14A9A8),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                  label: const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                                )
                              : Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0C7779)),
                                  child: IconButton(
                                    onPressed: () => setState(() => _isEditing = true),
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                  ),
                                ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Email Section
                      Text('Email', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF0C7779).withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.email_outlined, color: Color(0xFF0C7779), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(email, style: const TextStyle(fontSize: 16, color: Color(0xFF005461))),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      // Address Section
                      Text('Address', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _isEditingAddress
                                ? TextField(
                                    controller: _addressController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(Icons.location_on_outlined, color: Color(0xFF0C7779), size: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _initialAddress ?? '',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF005461)),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          _isEditingAddress
                              ? ElevatedButton.icon(
                                  onPressed: _saveAddress,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14A9A8),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                  label: const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                                )
                              : Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0C7779)),
                                  child: IconButton(
                                    onPressed: () => setState(() => _isEditingAddress = true),
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                  ),
                                ),
                        ],
                      ),

                      const Spacer(),

                      // Logout Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7377),
                            padding: const EdgeInsets.symmetric(horizontal: 125, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                              bottomNavigationBar: _buildBottomNavigationBar(),
                            );
                          }

                    // Bottom Navigation
                    Widget _buildBottomNavigationBar() {
                      return SizedBox(
                        height: 85,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C7779),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -5))],
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
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
                                          gradient: const LinearGradient(colors: [Color(0xFF14A9A8), Color(0xFF0C7779)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        ),
                                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
                                        ),
                                      const SizedBox(height: 6),
                                      const Text('Scan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget _buildNavItem(IconData iconInactive, IconData iconActive, String label, int index) {
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
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent),
                                  child: Icon(isSelected ? iconActive : iconInactive, color: Colors.white, size: 28),
                                ),
                                const SizedBox(height: 6),
                                Text(label, style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.2, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }