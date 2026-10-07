import 'package:flutter/material.dart';
import '../../../data/models/cashbook_model.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/repositories/cashbook_repository.dart';
import '../../../data/repositories/bank_repository.dart';

class CashbookViewModel extends ChangeNotifier {
  final CashbookRepository _cashbookRepo = CashbookRepository();
  final BankRepository _bankRepo = BankRepository();

  List<CashbookModel> _allTransactions = [];
  List<CashbookModel> _displayedTransactions = [];
  List<BankModel> _bankAccounts = [];
  BankModel? _selectedBankAccount; // null nghĩa là "Tất cả tài khoản"

  bool _isLoading = false;
  String _selectedTab = 'ALL'; // 'ALL', 'TIEN_MAT', 'TAI_KHOAN'

  List<CashbookModel> get transactions => _displayedTransactions;
  List<BankModel> get bankAccounts => _bankAccounts;
  BankModel? get selectedBankAccount => _selectedBankAccount;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;

  // 1. Quỹ tiền mặt
  double get cashIncome => _allTransactions
      .where((t) => t.isIncome && _isTienMat(t.loaiQuy))
      .fold(0.0, (sum, t) => sum + t.soTien);
  double get cashExpense => _allTransactions
      .where((t) => t.isExpense && _isTienMat(t.loaiQuy))
      .fold(0.0, (sum, t) => sum + t.soTien);
  double get cashBalance => cashIncome - cashExpense;

  // 2. Quỹ ngân hàng (Tất cả hoặc theo tài khoản đang chọn)
  double get bankIncome {
    return _allTransactions.where((t) {
      if (!t.isIncome || _isTienMat(t.loaiQuy)) return false;
      if (_selectedBankAccount != null) {
        return _matchesBank(t, _selectedBankAccount!);
      }
      return true;
    }).fold(0.0, (sum, t) => sum + t.soTien);
  }

  double get bankExpense {
    return _allTransactions.where((t) {
      if (!t.isExpense || _isTienMat(t.loaiQuy)) return false;
      if (_selectedBankAccount != null) {
        return _matchesBank(t, _selectedBankAccount!);
      }
      return true;
    }).fold(0.0, (sum, t) => sum + t.soTien);
  }

  double get bankBalance => bankIncome - bankExpense;

  // 3. TỔNG TỒN QUỸ (Bao gồm Tiền mặt + Tiền tài khoản ngân hàng)
  double get totalFund => cashBalance + bankBalance;

  // Tính số dư theo bộ lọc 1 hoặc nhiều chi nhánh
  double filteredCashBalance(bool Function(String?) matchesBranch) {
    final inc = _allTransactions
        .where((t) => t.isIncome && _isTienMat(t.loaiQuy) && matchesBranch(t.chiNhanh))
        .fold(0.0, (sum, t) => sum + t.soTien);
    final exp = _allTransactions
        .where((t) => t.isExpense && _isTienMat(t.loaiQuy) && matchesBranch(t.chiNhanh))
        .fold(0.0, (sum, t) => sum + t.soTien);
    return inc - exp;
  }

  double filteredBankBalance(bool Function(String?) matchesBranch) {
    final inc = _allTransactions.where((t) {
      if (!t.isIncome || _isTienMat(t.loaiQuy) || !matchesBranch(t.chiNhanh)) return false;
      if (_selectedBankAccount != null) {
        return _matchesBank(t, _selectedBankAccount!);
      }
      return true;
    }).fold(0.0, (sum, t) => sum + t.soTien);

    final exp = _allTransactions.where((t) {
      if (!t.isExpense || _isTienMat(t.loaiQuy) || !matchesBranch(t.chiNhanh)) return false;
      if (_selectedBankAccount != null) {
        return _matchesBank(t, _selectedBankAccount!);
      }
      return true;
    }).fold(0.0, (sum, t) => sum + t.soTien);

    return inc - exp;
  }

  double filteredTotalFund(bool Function(String?) matchesBranch) {
    return filteredCashBalance(matchesBranch) + filteredBankBalance(matchesBranch);
  }

  // Thu chi theo danh sách đang hiển thị
  double get totalIncome => _displayedTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.soTien);
  double get totalExpense => _displayedTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.soTien);
  double get balance => totalIncome - totalExpense;


  static bool _isTienMat(String loaiQuy) {
    final up = loaiQuy.toUpperCase();
    return up == 'TIEN_MAT' || up.contains('TIỀN MẶT') || up.contains('TIEN MAT');
  }

  static bool _matchesBank(CashbookModel t, BankModel bank) {
    final strCheck = '${t.loaiQuy} ${t.ghiChu} ${t.doiTuong}'.toUpperCase();
    final soTK = bank.soTK.toUpperCase().trim();
    final tenNH = bank.tenNH.toUpperCase().trim();
    final maNH = bank.maNH.toUpperCase().trim();
    if (maNH.isNotEmpty && strCheck.contains(maNH)) return true;
    if (soTK.isNotEmpty && strCheck.contains(soTK)) return true;
    if (tenNH.isNotEmpty && strCheck.contains(tenNH)) return true;
    return false;
  }

  Future<void> fetchTransactions([String? tab]) async {
    if (tab != null) _selectedTab = tab;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Tải danh sách ngân hàng nếu chưa có
      if (_bankAccounts.isEmpty) {
        _bankAccounts = await _bankRepo.fetchBankAccounts();
      }

      // 2. Tải tất cả giao dịch sổ quỹ
      _allTransactions = await _cashbookRepo.fetchTransactions(loaiQuy: 'ALL');
      _filterTransactions();
    } catch (e) {
      debugPrint("Lỗi tải sổ quỹ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchTab(String tab) {
    _selectedTab = tab;
    _filterTransactions();
    notifyListeners();
  }

  void selectBankAccount(BankModel? bank) {
    _selectedBankAccount = bank;
    _filterTransactions();
    notifyListeners();
  }

  void _filterTransactions() {
    _displayedTransactions = _allTransactions.where((t) {
      final isTm = _isTienMat(t.loaiQuy);

      if (_selectedTab == 'TIEN_MAT') {
        return isTm;
      } else if (_selectedTab == 'TAI_KHOAN') {
        if (isTm) return false;
        if (_selectedBankAccount != null) {
          return _matchesBank(t, _selectedBankAccount!);
        }
        return true;
      } else {
        // Tab 'ALL': Nếu có chọn lọc 1 tài khoản ngân hàng cụ thể thì chỉ lấy Tiền mặt + tài khoản đó
        if (_selectedBankAccount != null) {
          return isTm || _matchesBank(t, _selectedBankAccount!);
        }
        return true;
      }
    }).toList();
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
    await fetchTransactions();
  }
}
