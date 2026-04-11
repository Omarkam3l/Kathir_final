import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: ResponsiveUtils.iconSize(context, 64), color: Colors.black87),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 24), fontWeight: FontWeight.bold),
            ),
            const Text('System overview and management.'),
          ],
        ),
      ),
    );
  }
}
