import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Restaurant Dashboard screen - redirects to meals list
/// This is the main entry point for restaurant users
class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect to meals list on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/restaurant-dashboard/meals');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // This screen just redirects to meals list
    // The actual UI is in MealsListScreen
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
