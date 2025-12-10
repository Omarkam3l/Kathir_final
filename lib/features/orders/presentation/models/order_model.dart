import '../controllers/orders_controller.dart';

class OrderModel {
  final String id;
  final String title;
  final double price;
  final DateTime date;
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.title,
    required this.price,
    required this.date,
    required this.status,
  });
}
