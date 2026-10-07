import '../models/product_model.dart';
import '../services/supabase_service.dart';

class ProductRepository {
  Future<List<ProductModel>> fetchProducts() async {
    final List<dynamic> allRows = [];
    int from = 0;
    const int batchSize = 1000;

    while (true) {
      final response = await SupabaseService.client
          .from('dm_hanghoa')
          .select('*')
          .order('id', ascending: false)
          .range(from, from + batchSize - 1);

      final chunk = response as List;
      allRows.addAll(chunk);
      if (chunk.length < batchSize) break;
      from += batchSize;
    }

    final list = allRows
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
