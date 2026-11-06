import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/cashbook_model.dart';
import '../services/supabase_service.dart';

class CashbookRepository {
  List<CashbookModel>? _cachedTransactions;

  Future<List<CashbookModel>> fetchTransactions({String loaiQuy = 'ALL'}) async {
    try {
      var query = SupabaseService.client
          .from('so_quy')
          .select('*');

      if (loaiQuy != 'ALL') {
        query = query.eq('loai_quy', loaiQuy);
      }

      final response = await query.order('ngay_gd', ascending: false).limit(100);
      final list = (response as List)
          .map((item) => CashbookModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        _cachedTransactions = list;
        return list;
      }
    } catch (e) {
      debugPrint("Lỗi tải so_quy từ Supabase: $e. Sẽ nạp dữ liệu offline.");
    }

    if (_cachedTransactions == null) {
      try {
        final jsonStr = await rootBundle.loadString('assets/data/danh_sach_so_quy_full.json');
        final list = jsonDecode(jsonStr) as List;
        _cachedTransactions = list
            .map((item) => CashbookModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint("Lỗi nạp offline danh_sach_so_quy_full.json: $e");
        _cachedTransactions = [];
      }
    }

    if (loaiQuy == 'ALL') {
      return _cachedTransactions!;
    }
    return _cachedTransactions!
        .where((t) => t.loaiQuy.toUpperCase() == loaiQuy.toUpperCase())
        .toList();
  }

  Future<void> saveTransaction(CashbookModel transaction) async {
    if (_cachedTransactions != null) {
      _cachedTransactions!.removeWhere((t) => t.maPhieu == transaction.maPhieu);
      _cachedTransactions!.insert(0, transaction);
    }
    try {
      await SupabaseService.client
          .from('so_quy')
          .upsert(transaction.toJson());
    } catch (e) {
      debugPrint("Lỗi lưu sổ quỹ: $e");
    }
  }

  Future<void> updateTransaction(CashbookModel transaction) async {
    if (_cachedTransactions != null) {
      final idx = _cachedTransactions!.indexWhere((t) => t.maPhieu == transaction.maPhieu);
      if (idx >= 0) _cachedTransactions![idx] = transaction;
    }
    try {
      await SupabaseService.client
          .from('so_quy')
          .update(transaction.toJson())
          .eq('ma_phieu', transaction.maPhieu);
    } catch (e) {
      debugPrint("Lỗi cập nhật sổ quỹ: $e");
    }
  }

  Future<void> deleteTransaction(String maPhieu) async {
    if (_cachedTransactions != null) {
      _cachedTransactions!.removeWhere((t) => t.maPhieu == maPhieu);
    }
    try {
      await SupabaseService.client
          .from('so_quy')
          .delete()
          .eq('ma_phieu', maPhieu);
    } catch (e) {
      debugPrint("Lỗi xóa phiếu sổ quỹ: $e");
    }
  }
}
