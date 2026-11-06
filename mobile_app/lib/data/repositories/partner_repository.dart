import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/partner_model.dart';
import '../services/supabase_service.dart';

class PartnerRepository {
  List<PartnerModel>? _cachedCustomers;
  List<PartnerModel>? _cachedSuppliers;

  Future<List<PartnerModel>> fetchCustomers() async {
    try {
      final response = await SupabaseService.client
          .from('dm_doitac')
          .select('*')
          .eq('loai_doi_tac', 'KH')
          .order('ma_doi_tac', ascending: true);

      final list = (response as List)
          .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        _cachedCustomers = list;
        return list;
      }
    } catch (e) {
      debugPrint("Lỗi tải khách hàng từ Supabase: $e. Sẽ nạp dữ liệu offline.");
    }

    if (_cachedCustomers != null) return _cachedCustomers!;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_khach_hang_full.json');
      final list = jsonDecode(jsonStr) as List;
      _cachedCustomers = list
          .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedCustomers!;
    } catch (e) {
      debugPrint("Lỗi nạp offline danh_sach_khach_hang_full.json: $e");
      return [];
    }
  }

  Future<List<PartnerModel>> fetchSuppliers() async {
    try {
      final response = await SupabaseService.client
          .from('dm_doitac')
          .select('*')
          .eq('loai_doi_tac', 'NCC')
          .order('ma_doi_tac', ascending: true);

      final list = (response as List)
          .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        _cachedSuppliers = list;
        return list;
      }
    } catch (e) {
      debugPrint("Lỗi tải NCC từ Supabase: $e. Sẽ nạp dữ liệu offline.");
    }

    if (_cachedSuppliers != null) return _cachedSuppliers!;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/danh_sach_nha_cung_cap_full.json');
      final list = jsonDecode(jsonStr) as List;
      _cachedSuppliers = list
          .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedSuppliers!;
    } catch (e) {
      debugPrint("Lỗi nạp offline danh_sach_nha_cung_cap_full.json: $e");
      return [];
    }
  }

  Future<void> updateDebt(String maDoiTac, double newDebt) async {
    try {
      await SupabaseService.client
          .from('dm_doitac')
          .update({'cong_no': newDebt})
          .eq('ma_doi_tac', maDoiTac);
    } catch (e) {
      debugPrint("Lỗi cập nhật công nợ: $e");
    }
  }

  Future<PartnerModel?> createCustomer(PartnerModel customer) async {
    if (_cachedCustomers != null) {
      _cachedCustomers!.insert(0, customer);
    }
    try {
      final res = await SupabaseService.client
          .from('dm_doitac')
          .insert(customer.toJson())
          .select()
          .single();
      return PartnerModel.fromJson(res);
    } catch (e) {
      debugPrint("Lỗi tạo khách hàng: $e");
      return customer;
    }
  }
}
