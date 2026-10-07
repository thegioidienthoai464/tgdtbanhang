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
