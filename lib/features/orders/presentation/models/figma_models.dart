import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrderStage {
  final IconData icon;
  final String label;
  final String time;
  const OrderStage({required this.icon, required this.label, required this.time});
}

class DemoData {
  static List<OrderStage> orderTimeline(AppLocalizations l10n) {
    return [
      OrderStage(icon: Icons.receipt_long, label: l10n.orderPlacedStage, time: '09:12 AM'),
      OrderStage(icon: Icons.kitchen, label: l10n.preparingStage, time: '09:25 AM'),
      OrderStage(icon: Icons.delivery_dining, label: l10n.outForDeliveryStage, time: '09:45 AM'),
      OrderStage(icon: Icons.check_circle, label: l10n.deliveredStage, time: '10:10 AM'),
    ];
  }

  static List<NotificationItem> notifications(AppLocalizations l10n) {
    return [
      NotificationItem(
        title: l10n.notificationOrderOutForDeliveryTitle,
        description: l10n.notificationOrderOutForDeliveryBody,
        timeAgo: l10n.timeAgoMinutes(2),
        isNew: true,
      ),
      NotificationItem(
        title: l10n.notificationPromoTitle,
        description: l10n.notificationPromoBody,
        timeAgo: l10n.timeAgoHours(1),
        isNew: false,
      ),
      NotificationItem(
        title: l10n.notificationOrderDeliveredTitle,
        description: l10n.notificationOrderDeliveredBody,
        timeAgo: l10n.timeAgoYesterday,
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
