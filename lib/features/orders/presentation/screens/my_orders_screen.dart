import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controllers/orders_controller.dart';
import '../widgets/orders/order_list_item.dart';
import '../widgets/orders/order_tab_button.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  static const routeName = '/my-orders';
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<OrdersController>();
    final activeStatus = controller.activeTab;
    final orders = controller.ordersForActiveTab;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _OrdersAppBar(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  OrderTabButton(
                    label: l10n.currentTab,
                    isSelected: activeStatus == OrderStatus.current,
                    onTap: () => context
                        .read<OrdersController>()
                        .setActiveTab(OrderStatus.current),
                  ),
                  const SizedBox(width: 12),
                  OrderTabButton(
                    label: l10n.completedTab,
                    isSelected: activeStatus == OrderStatus.completed,
                    onTap: () => context
                        .read<OrdersController>()
                        .setActiveTab(OrderStatus.completed),
                  ),
                  const SizedBox(width: 12),
                  OrderTabButton(
                    label: l10n.cancelledTab,
                    isSelected: activeStatus == OrderStatus.cancelled,
                    onTap: () => context
                        .read<OrdersController>()
                        .setActiveTab(OrderStatus.cancelled),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderListItem(
                    order: order,
                    onTap: () => Navigator.of(context).pushNamed(
                      OrderDetailsScreen.routeName,
                      arguments: order,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersAppBar extends StatelessWidget {
  const _OrdersAppBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _diamondButton(
            context,
            icon: Icons.arrow_back_ios_new,
            onTap: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/home');
              }
            },
          ),
          Text(
            l10n.myOrdersTitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _diamondButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }
}
