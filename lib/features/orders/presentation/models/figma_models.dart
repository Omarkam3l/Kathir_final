import 'package:flutter/material.dart';

class OrderStage {
  final IconData icon;
  final String label;
  final String time;
  const OrderStage({required this.icon, required this.label, required this.time});
}

class DemoData {
  static List<OrderStage> orderTimeline() {
    return const [
      OrderStage(icon: Icons.receipt_long, label: 'Order placed', time: '09:12 AM'),
      OrderStage(icon: Icons.kitchen, label: 'Preparing', time: '09:25 AM'),
      OrderStage(icon: Icons.delivery_dining, label: 'Out for delivery', time: '09:45 AM'),
      OrderStage(icon: Icons.check_circle, label: 'Delivered', time: '10:10 AM'),
    ];
  }

  static List<NotificationItem> notifications() {
    return const [
      NotificationItem(
        title: 'Order #1028 is out for delivery',
        description: 'Your courier is on the way with your meal.',
        timeAgo: '2m ago',
        isNew: true,
      ),
      NotificationItem(
        title: 'Promo: 20% off on top restaurants',
        description: 'Grab exclusive deals from our best-rated partners.',
        timeAgo: '1h ago',
        isNew: false,
      ),
      NotificationItem(
        title: 'Order #1027 delivered',
        description: 'Hope you enjoyed your meal! Rate the experience.',
        timeAgo: 'Yesterday',
        isNew: false,
      ),
    ];
  }
}

class NotificationItem {
  final String title;
  final String description;
  final String timeAgo;
  final bool isNew;
  const NotificationItem({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.isNew,
  });
}
