import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../user_home/presentation/viewmodels/home_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../screens/home_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use persistent singleton ViewModel from DI
    return ChangeNotifierProvider.value(
      value: AppLocator.I.get<HomeViewModel>(),
      child: const _HomeWrapper(),
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  const _HomeWrapper();
  
  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Smart load: only fetches if data is stale or missing
      context.read<HomeViewModel>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

