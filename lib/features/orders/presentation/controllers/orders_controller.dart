import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

enum OrderStatus { current, completed, cancelled }

class OrdersController extends ChangeNotifier {
  OrderStatus _active = OrderStatus.current;
  final List<OrderModel> _orders = [
    OrderModel(
      id: '1',
      title: 'Veg Meal Combo',
      price: 9.99,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: OrderStatus.completed,
    ),
    OrderModel(
      id: '2',
      title: 'Chicken Bowl',
      price: 12.49,
      date: DateTime.now(),
      status: OrderStatus.current,
    ),
    OrderModel(
      id: '3',
      title: 'Pasta Box',
      price: 7.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: OrderStatus.cancelled,
    ),
  ];

  OrderStatus get activeTab => _active;
  List<OrderModel> get allOrders => List.unmodifiable(_orders);

  List<OrderModel> get ordersForActiveTab =>
      _orders.where((o) => o.status == _active).toList();

  void setActiveTab(OrderStatus status) {
    _active = status;
    notifyListeners();
  }
}
