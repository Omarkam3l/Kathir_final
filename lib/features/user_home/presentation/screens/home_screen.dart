import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../user_home/presentation/viewmodels/home_viewmodel.dart';
import '../../../user_home/presentation/controllers/home_controller.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../screens/home_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = AppLocator.I.get<HomeViewModel>();
    final controller = HomeController(vm);
    return ChangeNotifierProvider.value(
      value: vm,
      child: _HomeWrapper(controller: controller),
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  final HomeController controller;
  const _HomeWrapper({required this.controller});
  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

