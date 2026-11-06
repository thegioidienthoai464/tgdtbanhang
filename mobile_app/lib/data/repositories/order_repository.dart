import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OrderRepository {
  List<OrderModel>? _cachedOrders;

  Future<List<OrderModel>> fetchAllOrders() async {
    // 1. Thử tải từ Supabase
    try {
      final response = await SupabaseService.client
          .from('don_hang')
          .select('*')
          .order('ngay_ban', ascending: false);

      final list = (response as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        _cachedOrders = list;
        return list;
      }
    } catch (e) {
      debugPrint("Lỗi tải don_hang từ Supabase: $e. Sẽ nạp dữ liệu offline.");
    }

    if (_cachedOrders != null) return _cachedOrders!;

    // 2. Fallback nạp từ assets/data/danh_sach_don_hang_full.json
    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_don_hang_full.json');
      final list = jsonDecode(jsonStr) as List;
      _cachedOrders = list
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedOrders!;
    } catch (e) {
      debugPrint("Lỗi nạp offline danh_sach_don_hang_full.json: $e");
      return [];
    }
  }

  Future<List<OrderModel>> fetchPreOrders() async {
    final all = await fetchAllOrders();
    return all.where((o) => o.isPreOrder).toList();
  }

  Future<List<OrderModel>> fetchImportOrders() async {
    final all = await fetchAllOrders();
    return all.where((o) => o.isImportOrder && !o.maDonHang.startsWith('PNH_TON')).toList();
  }

  Future<void> saveOrder(OrderModel order) async {
    if (_cachedOrders != null) {
      _cachedOrders!.removeWhere((o) => o.maDonHang == order.maDonHang);
      _cachedOrders!.insert(0, order);
    }
    try {
      await SupabaseService.client
          .from('don_hang')
          .upsert(order.toJson());
    } catch (e) {
      debugPrint("Lỗi lưu don_hang lên Supabase: $e");
    }
  }

  Future<void> updateOrderStatus(String maDonHang, String newStatus) async {
    if (_cachedOrders != null) {
      final idx = _cachedOrders!.indexWhere((o) => o.maDonHang == maDonHang);
      if (idx >= 0) {
        // tạo bản sao với trạng thái mới
        final old = _cachedOrders![idx];
        _cachedOrders![idx] = OrderModel(
          maDonHang: old.maDonHang,
          ngayBan: old.ngayBan,
          maKH: old.maKH,
          tenKH: old.tenKH,
          soDienThoai: old.soDienThoai,
          chiNhanh: old.chiNhanh,
          tongTien: old.tongTien,
          giamGia: old.giamGia,
          khachPhaiTra: old.khachPhaiTra,
          khachTra: old.khachTra,
          hinhThucTT: old.hinhThucTT,
          nganHangNhan: old.nganHangNhan,
          chiTietSanPham: old.chiTietSanPham,
          trangThai: newStatus,
          nhanVien: old.nhanVien,
        );
      }
    }
    try {
      await SupabaseService.client
          .from('don_hang')
          .update({'trang_thai': newStatus})
          .eq('ma_don_hang', maDonHang);
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái đơn: $e");
    }
  }

  Future<void> deleteOrder(String maDonHang) async {
    if (_cachedOrders != null) {
      _cachedOrders!.removeWhere((o) => o.maDonHang == maDonHang);
    }
    try {
      await SupabaseService.client
          .from('don_hang')
          .delete()
          .eq('ma_don_hang', maDonHang);
      await SupabaseService.client
          .from('so_quy')
          .delete()
          .eq('ma_chung_tu', maDonHang);
    } catch (e) {
      debugPrint("Lỗi xóa đơn: $e");
    }
  }
}
