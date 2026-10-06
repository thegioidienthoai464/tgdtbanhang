import '../models/partner_model.dart';
import '../services/supabase_service.dart';

class PartnerRepository {
  Future<List<PartnerModel>> fetchCustomers() async {
    final response = await SupabaseService.client
        .from('dm_doitac')
        .select('*')
        .eq('loai_doi_tac', 'KH')
        .order('ma_doi_tac', ascending: true);

    return (response as List)
        .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PartnerModel>> fetchSuppliers() async {
    final response = await SupabaseService.client
        .from('dm_doitac')
        .select('*')
        .eq('loai_doi_tac', 'NCC')
        .order('ma_doi_tac', ascending: true);

    return (response as List)
        .map((item) => PartnerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateDebt(String maDoiTac, double newDebt) async {
    await SupabaseService.client
        .from('dm_doitac')
        .update({'cong_no': newDebt})
        .eq('ma_doi_tac', maDoiTac);
  }
}
