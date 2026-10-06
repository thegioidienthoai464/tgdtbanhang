import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<ProductModel> get products => _filteredProducts;
  bool get isLoading => _isLoading;

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
}
