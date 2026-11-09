import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_transfer_model.dart';
import '../../../data/models/stock_audit_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/stock_transfer_repository.dart';
import '../../../data/repositories/stock_audit_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final StockTransferRepository _transferRepo = StockTransferRepository();
  final StockAuditRepository _auditRepo = StockAuditRepository();

  // Tồn kho
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Chuyển kho & Kiểm kho
  List<StockTransferModel> _transfers = [];
  List<StockAuditModel> _audits = [];
  bool _isLoadingTransfers = false;
  bool _isLoadingAudits = false;

  List<ProductModel> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  List<StockTransferModel> get transfers => _transfers;
  bool get isLoadingTransfers => _isLoadingTransfers;
  List<StockAuditModel> get audits => _audits;
  bool get isLoadingAudits => _isLoadingAudits;

  double get totalStock => _allProducts.fold(0, (sum, p) => sum + p.tonKho);
  double get totalStockValue => _allProducts.fold(0, (sum, p) => sum + (p.tonKho * p.giaVon));

  Future<void> fetchInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _productRepo.fetchProducts();
      _applyFilter();
    } catch (e) {
      debugPrint("Lỗi tải tồn kho: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransfers() async {
    _isLoadingTransfers = true;
    notifyListeners();
    try {
      _transfers = await _transferRepo.fetchTransfers();
    } catch (e) {
      debugPrint("Lỗi tải chuyển kho: $e");
    } finally {
      _isLoadingTransfers = false;
      notifyListeners();
    }
  }

  Future<void> fetchAudits() async {
    _isLoadingAudits = true;
    notifyListeners();
    try {
      _audits = await _auditRepo.fetchAudits();
    } catch (e) {
      debugPrint("Lỗi tải kiểm kho: $e");
    } finally {
      _isLoadingAudits = false;
      notifyListeners();
    }
  }

  Future<bool> receiveTransfer(String maPhieu, String currentBranch) async {
    final ok = await _transferRepo.receiveTransfer(maPhieu, currentBranch);
    if (ok) {
      await fetchTransfers();
      await fetchInventory();
    }
    return ok;
  }

  Future<bool> cancelTransfer(String maPhieu) async {
    final ok = await _transferRepo.cancelTransfer(maPhieu);
    if (ok) {
      await fetchTransfers();
    }
    return ok;
  }

  Future<bool> saveTransfer(StockTransferModel transfer) async {
    final ok = await _transferRepo.saveTransfer(transfer);
    if (ok) {
      await fetchTransfers();
    }
    return ok;
  }

  Future<bool> balanceAudit(String maKiemKho) async {
    final ok = await _auditRepo.balanceAudit(maKiemKho);
    if (ok) {
      await fetchAudits();
      await fetchInventory();
    }
    return ok;
  }

  Future<bool> cancelAudit(String maKiemKho) async {
    final ok = await _auditRepo.cancelAudit(maKiemKho);
    if (ok) {
      await fetchAudits();
    }
    return ok;
  }

  Future<bool> saveAudit(StockAuditModel audit) async {
    final ok = await _auditRepo.saveAudit(audit);
    if (ok) {
      await fetchAudits();
    }
    return ok;
  }

  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((p) {
        return p.maHang.toLowerCase().contains(_searchQuery) ||
               p.tenHang.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();
    try {
      final created = await _productRepo.createProduct(product);
      if (created != null) {
        _allProducts.insert(0, created);
        _applyFilter();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi thêm hàng hóa: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _productRepo.updateProduct(product);
      if (updated != null) {
        final idx = _allProducts.indexWhere((p) => p.maHang == product.maHang);
        if (idx >= 0) {
          _allProducts[idx] = updated;
        }
        _applyFilter();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi cập nhật hàng hóa: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String maHang) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _productRepo.deleteProduct(maHang);
      _allProducts.removeWhere((p) => p.maHang == maHang);
      _applyFilter();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa hàng hóa: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
