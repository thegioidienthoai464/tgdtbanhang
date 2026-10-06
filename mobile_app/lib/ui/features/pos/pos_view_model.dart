import 'package:flutter/material.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/cashbook_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../../data/repositories/cashbook_repository.dart';
import '../../../data/services/lan_printer_service.dart';

class PosViewModel extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final PartnerRepository _partnerRepo = PartnerRepository();
  final CashbookRepository _cashbookRepo = CashbookRepository();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<PartnerModel> _customers = [];
  final List<OrderItemModel> _cart = [];
  PartnerModel? _selectedCustomer;
  
  bool _isLoading = false;
  String _searchQuery = '';
  String _paymentMethod = 'TIEN_MAT'; // 'TIEN_MAT', 'TAI_KHOAN', 'CON_NO'

  List<ProductModel> get products => _filteredProducts;
  List<PartnerModel> get customers => _customers;
  List<OrderItemModel> get cart => _cart;
  PartnerModel? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String get paymentMethod => _paymentMethod;

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.thanhTien);
  int get totalItemCount => _cart.fold(0, (sum, item) => sum + item.soLuong);

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _productRepo.fetchProducts();
      _filteredProducts = List.from(_allProducts);
      _customers = await _partnerRepo.fetchCustomers();
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu POS: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase().trim();
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

  void addToCart(ProductModel product) {
    final existingIdx = _cart.indexWhere((item) => item.maHang == product.maHang);
    if (existingIdx >= 0) {
      final existing = _cart[existingIdx];
      _cart[existingIdx] = OrderItemModel(
        maHang: existing.maHang,
        tenHang: existing.tenHang,
        soLuong: existing.soLuong + 1,
        donGia: existing.donGia,
        imeiStr: existing.imeiStr,
      );
    } else {
      _cart.add(OrderItemModel(
        maHang: product.maHang,
        tenHang: product.tenHang,
        soLuong: 1,
        donGia: product.giaBan,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String maHang, int delta) {
    final idx = _cart.indexWhere((item) => item.maHang == maHang);
    if (idx >= 0) {
      final current = _cart[idx];
      final newQty = current.soLuong + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx] = OrderItemModel(
          maHang: current.maHang,
          tenHang: current.tenHang,
          soLuong: newQty,
          donGia: current.donGia,
          imeiStr: current.imeiStr,
        );
      }
      notifyListeners();
    }
  }

  void setCustomer(PartnerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomer = null;
    _paymentMethod = 'TIEN_MAT';
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout() async {
    if (_cart.isEmpty) return {'success': false, 'message': 'Giỏ hàng đang trống'};
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final maDon = "HD${now.millisecondsSinceEpoch.toString().substring(5)}";
      final tongTien = subtotal;
      final daTra = _paymentMethod == 'CON_NO' ? 0.0 : tongTien;
      final khachPhaiTra = tongTien;

      final order = OrderModel(
        maDonHang: maDon,
        ngayBan: now,
        maKH: _selectedCustomer?.maDoiTac ?? 'KL',
        tenKH: _selectedCustomer?.tenDoiTac ?? 'Khách lẻ',
        soDienThoai: _selectedCustomer?.soDienThoai ?? '',
        tongTien: tongTien,
        khachPhaiTra: khachPhaiTra,
        khachTra: daTra,
        hinhThucTT: _paymentMethod,
        chiTietSanPham: List.from(_cart),
        trangThai: 'Hoàn thành',
      );

      // 1. Lưu đơn hàng lên Supabase
      await _orderRepo.saveOrder(order);

      // 2. Nếu khách nợ -> cập nhật công nợ
      if (_paymentMethod == 'CON_NO' && _selectedCustomer != null) {
        final newDebt = _selectedCustomer!.congNo + tongTien;
        await _partnerRepo.updateDebt(_selectedCustomer!.maDoiTac, newDebt);
      }

      // 3. Nếu khách trả tiền -> Ghi nhận vào Sổ Quỹ
      if (daTra > 0) {
        final maPT = "PT${now.millisecondsSinceEpoch.toString().substring(6)}";
        final phieuThu = CashbookModel(
          maPhieu: maPT,
          loaiPhieu: 'THU',
          loaiQuy: _paymentMethod,
          ngayGD: now,
          soTien: daTra,
          doiTuong: 'Khách hàng',
          maDoiTuong: _selectedCustomer?.maDoiTac ?? 'KL',
          maChungTu: maDon,
          ghiChu: 'Thu tiền bán hàng POS $maDon',
        );
        await _cashbookRepo.saveTransaction(phieuThu);
      }

      // 4. Trừ tồn kho sản phẩm
      for (final item in _cart) {
        final prod = _allProducts.firstWhere((p) => p.maHang == item.maHang, orElse: () => ProductModel(maHang: item.maHang, tenHang: item.tenHang));
        final newStock = (prod.tonKho - item.soLuong).clamp(0.0, 999999.0);
        await _productRepo.updateStock(item.maHang, newStock);
      }

      // 5. Tự động in hóa đơn qua máy in mạng LAN nếu được kích hoạt
      String printStatus = '';
      if (await LanPrinterService.isAutoPrintEnabled()) {
        final printRes = await LanPrinterService.printOrderReceipt(order);
        if (printRes['success'] == true) {
          printStatus = ' • Đã in bill LAN thành công!';
        } else {
          printStatus = ' • Chưa in được: ${printRes['message']}';
        }
      }

      clearCart();
      await initData();
      return {'success': true, 'message': 'Đơn hàng $maDon thành công!$printStatus'};
    } catch (e) {
      debugPrint("Lỗi thanh toán: $e");
      return {'success': false, 'message': 'Lỗi thanh toán: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
