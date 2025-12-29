import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class NgoDashboardScreen extends StatelessWidget {
  const NgoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'NGO Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Manage food requests and distribution.'),
          ],
        ),
      ),
    );
  }
}
