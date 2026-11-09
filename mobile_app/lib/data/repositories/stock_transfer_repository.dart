import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_transfer_model.dart';
import '../services/supabase_service.dart';

class StockTransferRepository {
  static const String _prefKey = 'tt_pos_chuyen_kho_local_list';
  List<StockTransferModel>? _cachedTransfers;

  Future<List<StockTransferModel>> fetchTransfers() async {
    if (_cachedTransfers != null && _cachedTransfers!.isNotEmpty) {
      return _cachedTransfers!;
    }

    final List<StockTransferModel> list = [];
    final Set<String> existingCodes = {};

    // 1. Nạp từ local modifications đã lưu trong SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_prefKey);
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is List) {
          for (final it in decoded) {
            if (it is Map) {
              try {
                final model = StockTransferModel.fromJson(Map<String, dynamic>.from(it));
                if (model.maPhieu.isNotEmpty && !existingCodes.contains(model.maPhieu)) {
                  list.add(model);
                  existingCodes.add(model.maPhieu);
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi nạp local SharedPreferences chuyển kho: $e");
    }

    // 2. Thử lấy từ Supabase (nếu có kết nối)
    try {
      final response = await SupabaseService.client
          .from('don_hang')
          .select('*')
          .eq('hinh_thuc_tt', 'CHUYEN_KHO')
          .order('ngay_ban', ascending: false)
          .timeout(const Duration(seconds: 2));

      if (response is List && response.isNotEmpty) {
        for (final row in response) {
          if (row is Map) {
            try {
              final model = StockTransferModel.fromJson(Map<String, dynamic>.from(row));
              if (model.maPhieu.isNotEmpty && !existingCodes.contains(model.maPhieu)) {
                list.add(model);
                existingCodes.add(model.maPhieu);
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 3. Nạp từ assets offline nếu cần
    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_chuyen_kho_full.json');
      final assetList = jsonDecode(jsonStr);
      if (assetList is List) {
        for (final it in assetList) {
          if (it is Map) {
            try {
              final model = StockTransferModel.fromJson(Map<String, dynamic>.from(it));
              if (model.maPhieu.isNotEmpty && !existingCodes.contains(model.maPhieu)) {
                list.add(model);
                existingCodes.add(model.maPhieu);
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi nạp assets chuyển kho: $e");
    }

    list.sort((a, b) => b.ngayChuyen.compareTo(a.ngayChuyen));
    _cachedTransfers = list;
    return _cachedTransfers!;
  }

  Future<void> saveLocalCache() async {
    if (_cachedTransfers == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_cachedTransfers!.take(200).map((e) => e.toJson()).toList());
      await prefs.setString(_prefKey, jsonStr);
    } catch (e) {
      debugPrint("Lỗi lưu cache chuyển kho: $e");
    }
  }

  Future<bool> receiveTransfer(String maPhieu, String currentBranch) async {
    final all = await fetchTransfers();
    final idx = all.indexWhere((p) => p.maPhieu == maPhieu);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = StockTransferModel(
        maPhieu: old.maPhieu,
        tuChiNhanh: old.tuChiNhanh,
        toiChiNhanh: old.toiChiNhanh,
        cnXuat: old.cnXuat,
        cnNhan: old.cnNhan,
        ngayChuyen: old.ngayChuyen,
        ngayNhan: DateTime.now(),
        nguoiTao: old.nguoiTao,
        ghiChu: old.ghiChu,
        trangThai: 'Đã nhận',
        tongSoLuong: old.tongSoLuong,
        tongTien: old.tongTien,
        chiTiet: old.chiTiet,
      );
      await saveLocalCache();

      // Đồng bộ Supabase nếu có mạng
      try {
        await SupabaseService.client
            .from('don_hang')
            .update({'trang_thai': 'Đã nhận', 'ghi_chu': 'Đã nhận tại $currentBranch'})
            .eq('ma_don_hang', maPhieu);
      } catch (_) {}
      return true;
    }
    return false;
  }

  Future<bool> cancelTransfer(String maPhieu) async {
    final all = await fetchTransfers();
    final idx = all.indexWhere((p) => p.maPhieu == maPhieu);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = StockTransferModel(
        maPhieu: old.maPhieu,
        tuChiNhanh: old.tuChiNhanh,
        toiChiNhanh: old.toiChiNhanh,
        cnXuat: old.cnXuat,
        cnNhan: old.cnNhan,
        ngayChuyen: old.ngayChuyen,
        ngayNhan: old.ngayNhan,
        nguoiTao: old.nguoiTao,
        ghiChu: '${old.ghiChu} (Đã hủy)'.trim(),
        trangThai: 'Đã hủy',
        tongSoLuong: old.tongSoLuong,
        tongTien: old.tongTien,
        chiTiet: old.chiTiet,
      );
      await saveLocalCache();

      try {
        await SupabaseService.client
            .from('don_hang')
            .update({'trang_thai': 'Đã hủy'})
            .eq('ma_don_hang', maPhieu);
      } catch (_) {}
      return true;
    }
    return false;
  }

  Future<bool> saveTransfer(StockTransferModel transfer) async {
    final all = await fetchTransfers();
    all.removeWhere((p) => p.maPhieu == transfer.maPhieu);
    all.insert(0, transfer);
    await saveLocalCache();

    try {
      await SupabaseService.client.from('don_hang').upsert({
        'ma_don_hang': transfer.maPhieu,
        'chi_nhanh': '${transfer.cnXuat} -> ${transfer.cnNhan}',
        'tong_tien': transfer.tongTien,
        'trang_thai': transfer.trangThai,
        'hinh_thuc_tt': 'CHUYEN_KHO',
        'chi_tiet': jsonEncode(transfer.chiTiet.map((e) => e.toJson()).toList()),
      });
    } catch (_) {}
    return true;
  }
}
