import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

class ProductRepository {
  Map<String, dynamic>? _baselineData;

  /// Nạp baseline dữ liệu tồn kho 3 chi nhánh từ file JSON đính kèm
  Future<Map<String, dynamic>> _loadBaselineData() async {
    if (_baselineData != null) return _baselineData!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/ton_kho_3_chinhanh.json');
      _baselineData = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Lỗi nạp baseline ton_kho_3_chinhanh.json: $e");
      _baselineData = {'tonKho': {}, 'giaVon': {}, 'imei': {}};
    }
    return _baselineData!;
  }

  Future<List<ProductModel>> fetchProducts() async {
    final List<dynamic> allRows = [];
    int from = 0;
    const int batchSize = 1000;

    // 1. Lấy toàn bộ danh mục hàng hóa từ Supabase
    while (true) {
      try {
        final response = await SupabaseService.client
            .from('dm_hanghoa')
            .select('*')
            .order('id', ascending: false)
            .range(from, from + batchSize - 1);

        final chunk = response as List;
        allRows.addAll(chunk);
        if (chunk.length < batchSize) break;
        from += batchSize;
      } catch (e) {
        debugPrint("Lỗi tải dm_hanghoa: $e");
        break;
      }
    }

    // 2. Tải baseline 3 chi nhánh từ file JSON
    final baseline = await _loadBaselineData();
    final rawTonKho = (baseline['tonKho'] as Map<String, dynamic>?) ?? {};
    final rawGiaVon = (baseline['giaVon'] as Map<String, dynamic>?) ?? {};

    // 3. Tải danh sách IMEI đang TrongKho từ Supabase kho_imei
    final Map<String, Map<String, List<String>>> imeiMap = {};
    try {
      final imeiResponse = await SupabaseService.client
          .from('kho_imei')
          .select('imei,ma_hang,chi_nhanh,trang_thai')
          .eq('trang_thai', 'TrongKho');

      if (imeiResponse is List) {
        for (final row in imeiResponse) {
          final ma = (row['ma_hang'] ?? '').toString().trim().toUpperCase();
          final cn = ProductModel.normalizeBranchCode((row['chi_nhanh'] ?? '').toString());
          final im = (row['imei'] ?? '').toString().trim();
          if (ma.isEmpty || im.isEmpty) continue;

          imeiMap.putIfAbsent(ma, () => {'CN01': [], 'CN02': [], 'CN03': [], 'CN04': []});
          imeiMap[ma]!.putIfAbsent(cn, () => []);
          if (!imeiMap[ma]![cn]!.contains(im)) {
            imeiMap[ma]![cn]!.add(im);
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải kho_imei: $e");
    }

    // 4. Tải các giao dịch thực tế từ don_hang để điều chỉnh tồn kho cho hàng không IMEI
    final Map<String, Map<String, double>> orderAdjustments = {};
    try {
      final ordersResponse = await SupabaseService.client
          .from('don_hang')
          .select('ma_don_hang,chi_nhanh,chi_tiet_san_pham,trang_thai');

      if (ordersResponse is List) {
        for (final dh in ordersResponse) {
          if (dh['trang_thai'] == 'Đã hủy') continue;
          final maDH = (dh['ma_don_hang'] ?? '').toString().toUpperCase();
          if (maDH.startsWith('PNH_TON_')) continue; // Bỏ qua phiếu giả lập nạp tồn ban đầu

          final cn = ProductModel.normalizeBranchCode((dh['chi_nhanh'] ?? '').toString());
          final items = dh['chi_tiet_san_pham'];
          if (items is List) {
            for (final it in items) {
              if (it is! Map) continue;
              final m = (it['maHang'] ?? it['ma_hang'] ?? '').toString().trim().toUpperCase();
              final sl = (it['soLuong'] as num?)?.toDouble() ?? 0.0;
              if (m.isEmpty || sl <= 0) continue;

              orderAdjustments.putIfAbsent(m, () => {'CN01': 0.0, 'CN02': 0.0, 'CN03': 0.0, 'CN04': 0.0});
              if (maDH.startsWith('PNH') || maDH.startsWith('TH')) {
                orderAdjustments[m]![cn] = (orderAdjustments[m]![cn] ?? 0.0) + sl;
              } else if (maDH.startsWith('HD') || maDH.startsWith('PNT')) {
                orderAdjustments[m]![cn] = (orderAdjustments[m]![cn] ?? 0.0) - sl;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải don_hang điều chỉnh tồn kho: $e");
    }

    // 5. Kết hợp và tính toán số lượng tồn kho chính xác theo từng chi nhánh
    final List<ProductModel> list = [];
    for (final item in allRows) {
      final p = ProductModel.fromJson(item as Map<String, dynamic>);
      final maHang = p.maHang.trim().toUpperCase();

      // Lấy tồn ban đầu từ baseline Excel
      final baselineTon = (rawTonKho[maHang] as List?) ?? [];
      double cn01 = (baselineTon.isNotEmpty && baselineTon[0] != null) ? (baselineTon[0] as num).toDouble() : p.tonKho;
      double cn02 = (baselineTon.length > 1 && baselineTon[1] != null) ? (baselineTon[1] as num).toDouble() : 0.0;
      double cn03 = (baselineTon.length > 2 && baselineTon[2] != null) ? (baselineTon[2] as num).toDouble() : 0.0;

      // Lấy giá vốn ban đầu theo chi nhánh
      final baselineGv = (rawGiaVon[maHang] as List?) ?? [];
      final gv01 = (baselineGv.isNotEmpty && (baselineGv[0] as num) > 0) ? (baselineGv[0] as num).toDouble() : p.giaVon;
      final gv02 = (baselineGv.length > 1 && (baselineGv[1] as num) > 0) ? (baselineGv[1] as num).toDouble() : (p.giaVon > 0 ? p.giaVon : gv01);
      final gv03 = (baselineGv.length > 2 && (baselineGv[2] as num) > 0) ? (baselineGv[2] as num).toDouble() : (p.giaVon > 0 ? p.giaVon : gv01);

      // Xử lý sản phẩm IMEI
      final productImeis = imeiMap[maHang] ?? {'CN01': [], 'CN02': [], 'CN03': [], 'CN04': []};
      final bool hasImeisInDb = productImeis.values.any((l) => l.isNotEmpty);
      final bool isImeiTracked = p.coQuanLyImei || hasImeisInDb;

      if (isImeiTracked) {
        cn01 = (productImeis['CN01']?.length ?? 0).toDouble();
        cn02 = (productImeis['CN02']?.length ?? 0).toDouble();
        cn03 = (productImeis['CN03']?.length ?? 0).toDouble();
      } else {
        final adj = orderAdjustments[maHang];
        if (adj != null) {
          cn01 = (cn01 + (adj['CN01'] ?? 0.0)).clamp(0.0, double.infinity);
          cn02 = (cn02 + (adj['CN02'] ?? 0.0)).clamp(0.0, double.infinity);
          cn03 = (cn03 + (adj['CN03'] ?? 0.0)).clamp(0.0, double.infinity);
        }
      }

      final stockMap = {
        'CN01': cn01,
        'CN02': cn02,
        'CN03': cn03,
        'CN04': 0.0,
      };

      final costMap = {
        'CN01': gv01,
        'CN02': gv02,
        'CN03': gv03,
        'CN04': p.giaVon,
      };

      list.add(p.copyWith(
        coQuanLyImei: isImeiTracked,
        tonKho: cn01 + cn02 + cn03,
        tonKhoTheoChiNhanh: stockMap,
        giaVonTheoChiNhanh: costMap,
        imeiTheoChiNhanh: productImeis,
      ));
    }

    return list;
  }

  Future<void> updateStock(String maHang, double newStock) async {
    await SupabaseService.client
        .from('dm_hanghoa')
        .update({'ton_kho': newStock})
        .eq('ma_hang', maHang);
  }

  Future<List<String>> fetchImeis(String maHang, {String? branchCode}) async {
    var query = SupabaseService.client
        .from('kho_imei')
        .select('imei,chi_nhanh')
        .eq('ma_hang', maHang)
        .eq('trang_thai', 'TrongKho');

    final response = await query;
    final list = response as List;

    if (branchCode != null && branchCode.toUpperCase() != 'ALL') {
      final target = ProductModel.normalizeBranchCode(branchCode);
      return list
          .where((e) => ProductModel.normalizeBranchCode((e['chi_nhanh'] ?? '').toString()) == target)
          .map((e) => (e['imei'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return list
        .map((e) => (e['imei'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<ProductModel?> createProduct(ProductModel product) async {
    final response = await SupabaseService.client
        .from('dm_hanghoa')
        .insert(product.toJson())
        .select()
        .single();
    return ProductModel.fromJson(response);
  }

  Future<ProductModel?> updateProduct(ProductModel product) async {
    final response = await SupabaseService.client
        .from('dm_hanghoa')
        .update(product.toJson())
        .eq('ma_hang', product.maHang)
        .select()
        .single();
    return ProductModel.fromJson(response);
  }

  Future<void> deleteProduct(String maHang) async {
    await SupabaseService.client
        .from('dm_hanghoa')
        .delete()
        .eq('ma_hang', maHang);
  }
}
