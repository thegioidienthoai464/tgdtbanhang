import '../models/cashbook_model.dart';
import '../services/supabase_service.dart';

class CashbookRepository {
  Future<List<CashbookModel>> fetchTransactions({String loaiQuy = 'ALL'}) async {
    var query = SupabaseService.client
        .from('so_quy')
        .select('*');

    if (loaiQuy != 'ALL') {
      query = query.eq('loai_quy', loaiQuy);
    }

    final response = await query.order('ngay_gd', ascending: false).limit(100);

    return (response as List)
        .map((item) => CashbookModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransaction(CashbookModel transaction) async {
    await SupabaseService.client
        .from('so_quy')
        .upsert(transaction.toJson());
  }

  Future<void> updateTransaction(CashbookModel transaction) async {
    await SupabaseService.client
        .from('so_quy')
        .update(transaction.toJson())
        .eq('ma_phieu', transaction.maPhieu);
  }

  Future<void> deleteTransaction(String maPhieu) async {
    await SupabaseService.client
        .from('so_quy')
        .delete()
        .eq('ma_phieu', maPhieu);
  }
}
