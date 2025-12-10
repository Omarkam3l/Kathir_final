import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const routeName = '/order-details';
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: order == null
            ? const Text('No order provided')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('ID: ${order.id}'),
                  const SizedBox(height: 8),
                  Text('Price: \$${order.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Date: ${order.date.toLocal()}'),
                ],
              ),
      ),
    );
  }
}
