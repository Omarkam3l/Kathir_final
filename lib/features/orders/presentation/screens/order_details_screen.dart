import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const routeName = '/order-details';
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: order == null
            ? Text(l10n.noOrderProvided)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(l10n.orderIdLabel(order.id)),
                  const SizedBox(height: 8),
                  Text(l10n.orderPriceLabel('\$${order.price.toStringAsFixed(2)}')),
                  const SizedBox(height: 8),
                  Text(l10n.orderDateLabel(order.date.toLocal().toString())),
                ],
              ),
      ),
    );
  }
}
