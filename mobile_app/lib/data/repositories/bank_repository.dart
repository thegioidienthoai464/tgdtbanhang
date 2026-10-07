import '../models/bank_model.dart';
import '../services/supabase_service.dart';

class BankRepository {
  Future<List<BankModel>> fetchBankAccounts() async {
    try {
      final response = await SupabaseService.client
          .from('dm_nganhang')
          .select('*')
          .order('ma_nh', ascending: true);

      return (response as List)
          .map((item) => BankModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback danh sách mặc định nếu chưa có trên database
      return [
        BankModel(
          maNH: 'NH01',
          tenNH: 'MB Bank',
          soTK: '0988888888',
          chuTK: 'THE GIOI DIEN THOAI',
        ),
      ];
    }
  }
}
