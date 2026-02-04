import 'package:flutter/material.dart';
import 'auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Product Scanner!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'User ID: ${user.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}