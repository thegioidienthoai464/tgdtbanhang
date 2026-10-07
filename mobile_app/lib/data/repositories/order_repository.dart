import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OrderRepository {
  Future<List<OrderModel>> fetchAllOrders() async {
    final response = await SupabaseService.client
        .from('don_hang')
        .select('*')
        .order('ngay_ban', ascending: false);

    return (response as List)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> fetchPreOrders() async {
    final response = await SupabaseService.client
        .from('don_hang')
        .select('*')
        .like('ma_don_hang', 'DDH%')
        .order('ngay_ban', ascending: false);

    return (response as List)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> fetchImportOrders() async {
    final response = await SupabaseService.client
        .from('don_hang')
        .select('*')
        .like('ma_don_hang', 'PNH%')
        .not('ma_don_hang', 'like', 'PNH_TON%')
        .order('ngay_ban', ascending: false);

    return (response as List)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveOrder(OrderModel order) async {
    await SupabaseService.client
        .from('don_hang')
        .upsert(order.toJson());
  }

  Future<void> updateOrderStatus(String maDonHang, String newStatus) async {
    await SupabaseService.client
        .from('don_hang')
        .update({'trang_thai': newStatus})
        .eq('ma_don_hang', maDonHang);
  }

  Future<void> deleteOrder(String maDonHang) async {
    await SupabaseService.client
        .from('don_hang')
        .delete()
        .eq('ma_don_hang', maDonHang);
    await SupabaseService.client
        .from('so_quy')
        .delete()
        .eq('ma_chung_tu', maDonHang);
  }
}
