import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/user_role.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/role_selection_viewmodel.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/role';
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserRole _selected = UserRole.ngo;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final roleVm = RoleSelectionViewModel(authViewModel: authVm);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your role:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: UserRole.values.map((r) {
                final isSelected = _selected == r;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selected = r;
                      if (isSelected) {
                        _anim.reverse();
                      } else {
                        _anim.forward();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? Colors.red : Colors.transparent),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedScale(
                          scale: isSelected ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(_iconForRole(r),
                              color: isSelected ? Colors.red : Colors.black54)),
                      const SizedBox(width: 8),
                      Text(r.name,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.red : Colors.black87)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () {
                  roleVm.selectRole(_selected);
                  GoRouter.of(context).go('/auth');
                },
                child: const Text('Confirm'))
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(UserRole r) {
    switch (r) {
      case UserRole.user:
        return Icons.person;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.ngo:
        return Icons.group;
      case UserRole.restaurant:
        return Icons.restaurant;
    }
  }
}
