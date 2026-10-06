import 'package:flutter/material.dart';
import '../../../data/models/cashbook_model.dart';
import '../../../data/repositories/cashbook_repository.dart';

class CashbookViewModel extends ChangeNotifier {
  final CashbookRepository _cashbookRepo = CashbookRepository();

  List<CashbookModel> _transactions = [];
  bool _isLoading = false;
  String _selectedTab = 'ALL'; // 'ALL', 'TIEN_MAT', 'TAI_KHOAN'

  List<CashbookModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;

  double get totalIncome => _transactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.soTien);
  double get totalExpense => _transactions.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.soTien);
  double get balance => totalIncome - totalExpense;

  Future<void> fetchTransactions([String tab = 'ALL']) async {
    _selectedTab = tab;
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _cashbookRepo.fetchTransactions(loaiQuy: _selectedTab);
    } catch (e) {
      debugPrint("Lỗi tải sổ quỹ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String loaiPhieu,
    required String loaiQuy,
    required double soTien,
    required String doiTuong,
    required String ghiChu,
    String? chiNhanh,
  }) async {
    final now = DateTime.now();
    final prefix = loaiPhieu == 'THU' ? 'PT' : 'PC';
    final maPhieu = "$prefix${now.millisecondsSinceEpoch.toString().substring(6)}";

    final tx = CashbookModel(
      maPhieu: maPhieu,
      chiNhanh: chiNhanh ?? 'CN01: Trụ sở chính',
      loaiPhieu: loaiPhieu,
      loaiQuy: loaiQuy,
      ngayGD: now,
      soTien: soTien,
      doiTuong: doiTuong,
      ghiChu: ghiChu,
    );

    await _cashbookRepo.saveTransaction(tx);
    await fetchTransactions(_selectedTab);
  }
}
