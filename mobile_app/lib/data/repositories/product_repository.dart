import '../models/product_model.dart';
import '../services/supabase_service.dart';

class ProductRepository {
  Future<List<ProductModel>> fetchProducts() async {
    final response = await SupabaseService.client
        .from('dm_hanghoa')
        .select('*')
        .order('id', ascending: true);
    
    final list = (response as List)
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> updateStock(String maHang, double newStock) async {
    await SupabaseService.client
        .from('dm_hanghoa')
        .update({'ton_kho': newStock})
        .eq('ma_hang', maHang);
  }

  Future<List<String>> fetchImeis(String maHang) async {
    final response = await SupabaseService.client
        .from('kho_imei')
        .select('imei')
        .eq('ma_hang', maHang)
        .eq('trang_thai', 'TrongKho');

    return (response as List)
        .map((e) => (e['imei'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
