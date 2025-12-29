import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class RestaurantDashboardScreen extends StatelessWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Restaurant Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Manage your menu and orders here.'),
          ],
        ),
      ),
    );
  }
}
