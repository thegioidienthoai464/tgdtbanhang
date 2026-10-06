import 'package:flutter/material.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class OrdersViewModel extends ChangeNotifier {
  final OrderRepository _orderRepo = OrderRepository();

  List<OrderModel> _preOrders = [];
  List<OrderModel> _salesOrders = [];
  List<OrderModel> _importOrders = [];
  bool _isLoading = false;

  List<OrderModel> get preOrders => _preOrders;
  List<OrderModel> get salesOrders => _salesOrders;
  List<OrderModel> get importOrders => _importOrders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _orderRepo.fetchAllOrders();
      _preOrders = all.where((o) => o.isPreOrder).toList();
      _importOrders = all.where((o) => o.isImportOrder).toList();
      _salesOrders = all.where((o) => o.isPosSale).toList();
    } catch (e) {
      debugPrint("Lỗi tải đơn hàng: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String maDonHang) async {
    try {
      await _orderRepo.updateOrderStatus(maDonHang, 'Đã hủy');
      await fetchOrders();
    } catch (e) {
      debugPrint("Lỗi hủy đơn: $e");
    }
  }
}
