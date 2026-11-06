import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bank_model.dart';
import '../services/supabase_service.dart';

class BankRepository {
  List<BankModel>? _cachedBanks;

  Future<List<BankModel>> fetchBankAccounts() async {
    try {
      final response = await SupabaseService.client
          .from('dm_nganhang')
          .select('*')
          .order('ma_nh', ascending: true);

      final list = (response as List)
          .map((item) => BankModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        _cachedBanks = list;
        return list;
      }
    } catch (e) {
      debugPrint("Lỗi tải dm_nganhang từ Supabase: $e. Sẽ nạp dữ liệu offline.");
    }

    if (_cachedBanks != null) return _cachedBanks!;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_ngan_hang_full.json');
      final list = jsonDecode(jsonStr) as List;
      _cachedBanks = list
          .map((item) => BankModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedBanks!;
    } catch (e) {
      debugPrint("Lỗi nạp offline danh_sach_ngan_hang_full.json: $e");
      return [
        BankModel(
          maNH: 'NH_01',
          tenNH: 'VietinBank - TG. DT khách CK KHD',
          soTK: '106884012495',
          chuTK: 'TG. DT khách CK KHD',
        ),
      ];
    }
  }
}
