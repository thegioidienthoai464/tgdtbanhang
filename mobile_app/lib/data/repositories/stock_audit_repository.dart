import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_audit_model.dart';
import '../services/supabase_service.dart';

class StockAuditRepository {
  static const String _prefKey = 'tt_pos_kiem_kho_local_list';
  List<StockAuditModel>? _cachedAudits;

  Future<List<StockAuditModel>> fetchAudits() async {
    if (_cachedAudits != null && _cachedAudits!.isNotEmpty) {
      return _cachedAudits!;
    }

    final List<StockAuditModel> list = [];
    final Set<String> existingCodes = {};

    // 1. Nạp từ local modifications SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_prefKey);
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is List) {
          for (final it in decoded) {
            if (it is Map) {
              try {
                final model = StockAuditModel.fromJson(Map<String, dynamic>.from(it));
                if (model.maKiemKho.isNotEmpty && !existingCodes.contains(model.maKiemKho)) {
                  list.add(model);
                  existingCodes.add(model.maKiemKho);
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi nạp local SharedPreferences kiểm kho: $e");
    }

    // 2. Nạp từ assets offline nếu cần
    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_kiem_kho_full.json');
      final assetList = jsonDecode(jsonStr);
      if (assetList is List) {
        for (final it in assetList) {
          if (it is Map) {
            try {
              final model = StockAuditModel.fromJson(Map<String, dynamic>.from(it));
              if (model.maKiemKho.isNotEmpty && !existingCodes.contains(model.maKiemKho)) {
                list.add(model);
                existingCodes.add(model.maKiemKho);
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi nạp assets kiểm kho: $e");
    }

    list.sort((a, b) => b.thoiGian.compareTo(a.thoiGian));
    _cachedAudits = list;
    return _cachedAudits!;
  }

  Future<void> saveLocalCache() async {
    if (_cachedAudits == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_cachedAudits!.take(100).map((e) => e.toJson()).toList());
      await prefs.setString(_prefKey, jsonStr);
    } catch (e) {
      debugPrint("Lỗi lưu cache kiểm kho: $e");
    }
  }

  Future<bool> balanceAudit(String maKiemKho) async {
    final all = await fetchAudits();
    final idx = all.indexWhere((p) => p.maKiemKho == maKiemKho);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = StockAuditModel(
        maKiemKho: old.maKiemKho,
        thoiGian: old.thoiGian,
        ngayCanBang: DateTime.now(),
        chiNhanh: old.chiNhanh,
        ghiChu: old.ghiChu,
        trangThai: 'Đã cân bằng kho',
        tongSoLuongThucTe: old.tongSoLuongThucTe,
        tongSoLuongLech: old.tongSoLuongLech,
        tongGiaTriChenhLech: old.tongGiaTriChenhLech,
        chiTiet: old.chiTiet,
      );
      await saveLocalCache();
      return true;
    }
    return false;
  }

  Future<bool> cancelAudit(String maKiemKho) async {
    final all = await fetchAudits();
    final idx = all.indexWhere((p) => p.maKiemKho == maKiemKho);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = StockAuditModel(
        maKiemKho: old.maKiemKho,
        thoiGian: old.thoiGian,
        ngayCanBang: old.ngayCanBang,
        chiNhanh: old.chiNhanh,
        ghiChu: '${old.ghiChu} (Đã hủy)'.trim(),
        trangThai: 'Đã hủy',
        tongSoLuongThucTe: old.tongSoLuongThucTe,
        tongSoLuongLech: old.tongSoLuongLech,
        tongGiaTriChenhLech: old.tongGiaTriChenhLech,
        chiTiet: old.chiTiet,
      );
      await saveLocalCache();
      return true;
    }
    return false;
  }

  Future<bool> saveAudit(StockAuditModel audit) async {
    final all = await fetchAudits();
    all.removeWhere((p) => p.maKiemKho == audit.maKiemKho);
    all.insert(0, audit);
    await saveLocalCache();
    return true;
  }
}
