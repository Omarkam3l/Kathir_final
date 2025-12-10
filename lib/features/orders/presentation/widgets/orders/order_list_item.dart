import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class OrderListItem extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  const OrderListItem({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = '${order.date.toLocal().toString().split(' ').first} • '
        '${order.status.name}';
    return Card(
      child: ListTile(
        title: Text(order.title),
        subtitle: Text(subtitle),
        trailing: Text('\$${order.price.toStringAsFixed(2)}'),
        onTap: onTap,
      ),
    );
  }
}
