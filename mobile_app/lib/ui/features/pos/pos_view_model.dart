import 'package:flutter/material.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/cashbook_model.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../../data/repositories/cashbook_repository.dart';
import '../../../data/repositories/bank_repository.dart';
import '../../../data/services/lan_printer_service.dart';

class PosViewModel extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final PartnerRepository _partnerRepo = PartnerRepository();
  final CashbookRepository _cashbookRepo = CashbookRepository();
  final BankRepository _bankRepo = BankRepository();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<PartnerModel> _customers = [];
  List<BankModel> _bankAccounts = [];
  final List<OrderItemModel> _cart = [];
  
  static final PartnerModel defaultCustomer = PartnerModel(
    maDoiTac: 'KHACHLE',
    tenDoiTac: 'Khách lẻ',
    soDienThoai: '',
    diaChi: '',
    loaiDoiTac: 'KH',
    congNo: 0.0,
    trangThai: 'HoatDong',
  );

  PartnerModel? _selectedCustomer = defaultCustomer;
  BankModel? _selectedBank;
  
  bool _isLoading = false;
  String _searchQuery = '';
  String _paymentMethod = 'TIEN_MAT'; // 'TIEN_MAT', 'TAI_KHOAN', 'HON_HOP', 'CON_NO'

  List<ProductModel> get products => _filteredProducts;
  List<PartnerModel> get customers => _customers;
  List<BankModel> get bankAccounts => _bankAccounts;
  List<OrderItemModel> get cart => _cart;
  PartnerModel? get selectedCustomer => _selectedCustomer;
  BankModel? get selectedBank => _selectedBank;
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
      _bankAccounts = await _bankRepo.fetchBankAccounts();
      if (_bankAccounts.isNotEmpty && _selectedBank == null) {
        _selectedBank = _bankAccounts.first;
      }
      // Đảm bảo khách hàng mặc định luôn là KHACHLE nếu chưa chọn khách quen
      final khachLe = _customers.firstWhere(
        (c) => c.maDoiTac.trim().toUpperCase() == 'KHACHLE',
        orElse: () => defaultCustomer,
      );
      if (_selectedCustomer == null || _selectedCustomer!.maDoiTac.trim().toUpperCase() == 'KHACHLE') {
        _selectedCustomer = khachLe;
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu POS: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductModel? findProductByBarcode(String barcode) {
    final clean = barcode.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final p in _allProducts) {
      if (p.maHang.trim().toLowerCase() == clean) {
        return p;
      }
    }
    for (final p in _allProducts) {
      if (p.maHang.trim().toLowerCase().contains(clean)) {
        return p;
      }
    }
    for (final p in _allProducts) {
      if (p.tenHang.trim().toLowerCase().contains(clean)) {
        return p;
      }
    }
    return null;
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
    if (customer == null) {
      final khachLe = _customers.firstWhere(
        (c) => c.maDoiTac.trim().toUpperCase() == 'KHACHLE',
        orElse: () => defaultCustomer,
      );
      _selectedCustomer = khachLe;
    } else {
      _selectedCustomer = customer;
    }
    notifyListeners();
  }

  void setSelectedBank(BankModel? bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<PartnerModel?> createQuickCustomer(String name, String phone) async {
    final now = DateTime.now();
    final ma = "KH${now.millisecondsSinceEpoch.toString().substring(7)}";
    return createFullCustomer(
      maKH: ma,
      tenKH: name,
      soDienThoai: phone,
    );
  }

  Future<PartnerModel?> createFullCustomer({
    required String maKH,
    required String tenKH,
    String soDienThoai = '',
    String diaChi = '',
    double congNo = 0.0,
    String ghiChu = '',
  }) async {
    try {
      final newCust = PartnerModel(
        maDoiTac: maKH.trim(),
        tenDoiTac: tenKH.trim(),
        soDienThoai: soDienThoai.trim(),
        diaChi: diaChi.trim(),
        loaiDoiTac: 'KH',
        congNo: congNo,
        trangThai: 'HoatDong',
        ghiChu: ghiChu.trim(),
      );
      final created = await _partnerRepo.createCustomer(newCust);
      if (created != null) {
        _customers.insert(0, created);
        _selectedCustomer = created;
        notifyListeners();
        return created;
      }
    } catch (e) {
      debugPrint("Lỗi tạo khách hàng: $e");
    }
    return null;
  }

  void clearCart() {
    _cart.clear();
    final khachLe = _customers.firstWhere(
      (c) => c.maDoiTac.trim().toUpperCase() == 'KHACHLE',
      orElse: () => defaultCustomer,
    );
    _selectedCustomer = khachLe;
    _paymentMethod = 'TIEN_MAT';
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout({
    String? chiNhanh,
    required double customerPaid,
    required String paymentMethod,
    BankModel? bankAccount,
    double cashAmount = 0.0,
    double bankTransferAmount = 0.0,
    bool applySurplusToDebt = true,
  }) async {
    if (_cart.isEmpty) return {'success': false, 'message': 'Giỏ hàng đang trống'};
    
    final total = subtotal;
    final paid = customerPaid;
    final debtDelta = total - paid; // > 0: khách thiếu nợ thêm; < 0: khách thừa

    final isKhachLe = _selectedCustomer == null || 
        _selectedCustomer!.maDoiTac.trim().toUpperCase() == 'KHACHLE';

    // Ràng buộc an toàn: Nếu khách thiếu nợ thì phải có thông tin khách hàng cụ thể
    if (debtDelta > 0 && isKhachLe) {
      return {
        'success': false, 
        'message': 'Khách còn thiếu nợ. Vui lòng chọn khách hàng cụ thể (không phải Khách lẻ) để ghi nhận công nợ!'
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final maDon = "HD${now.millisecondsSinceEpoch.toString().substring(5)}";
      final branch = chiNhanh ?? 'CN01: Trụ sở chính';
      final bankName = (paymentMethod == 'TAI_KHOAN' || paymentMethod == 'HON_HOP')
          ? (bankAccount?.displayName ?? _selectedBank?.displayName)
          : null;

      final order = OrderModel(
        maDonHang: maDon,
        ngayBan: now,
        maKH: (_selectedCustomer != null && _selectedCustomer!.maDoiTac.trim().isNotEmpty)
            ? _selectedCustomer!.maDoiTac.trim()
            : 'KHACHLE',
        tenKH: (_selectedCustomer != null && _selectedCustomer!.tenDoiTac.trim().isNotEmpty)
            ? _selectedCustomer!.tenDoiTac.trim()
            : 'Khách lẻ',
        soDienThoai: _selectedCustomer?.soDienThoai ?? '',
        chiNhanh: branch,
        tongTien: total,
        khachPhaiTra: total,
        khachTra: paid,
        hinhThucTT: paymentMethod,
        nganHangNhan: bankName,
        chiTietSanPham: List.from(_cart),
        trangThai: 'Hoàn thành',
      );

      // 1. Lưu đơn hàng lên Supabase
      await _orderRepo.saveOrder(order);

      // 2. Cập nhật công nợ khách hàng (Thiếu nợ hoặc Trả thừa cấn trừ nợ) - không áp dụng cho Khách lẻ KHACHLE
      if (_selectedCustomer != null && !isKhachLe) {
        if (debtDelta > 0) {
          // Khách trả thiếu -> cộng thêm vào công nợ
          final newDebt = _selectedCustomer!.congNo + debtDelta;
          await _partnerRepo.updateDebt(_selectedCustomer!.maDoiTac, newDebt);
        } else if (debtDelta < 0 && applySurplusToDebt) {
          // Khách trả thừa và chọn tính vào công nợ -> trừ bớt nợ cũ
          final newDebt = _selectedCustomer!.congNo + debtDelta; // debtDelta là số âm
          await _partnerRepo.updateDebt(_selectedCustomer!.maDoiTac, newDebt);
        }
      }

      // 3. Ghi nhận vào Sổ Quỹ (so_quy)
      if (paymentMethod == 'TIEN_MAT' && paid > 0) {
        final maPT = "PT${now.millisecondsSinceEpoch.toString().substring(6)}";
        final phieuThu = CashbookModel(
          maPhieu: maPT,
          chiNhanh: branch,
          loaiPhieu: 'THU',
          loaiQuy: 'TIEN_MAT',
          ngayGD: now,
          soTien: paid,
          doiTuong: 'Khách hàng',
          maDoiTuong: _selectedCustomer?.maDoiTac ?? 'KHACHLE',
          maChungTu: maDon,
          ghiChu: 'Thu tiền mặt bán hàng POS $maDon',
        );
        await _cashbookRepo.saveTransaction(phieuThu);
      } else if (paymentMethod == 'TAI_KHOAN' && paid > 0) {
        final maPT = "PT${now.millisecondsSinceEpoch.toString().substring(6)}";
        final phieuThu = CashbookModel(
          maPhieu: maPT,
          chiNhanh: branch,
          loaiPhieu: 'THU',
          loaiQuy: bankName ?? 'TAI_KHOAN',
          ngayGD: now,
          soTien: paid,
          doiTuong: 'Khách hàng',
          maDoiTuong: _selectedCustomer?.maDoiTac ?? 'KHACHLE',
          maChungTu: maDon,
          ghiChu: 'Thu chuyển khoản bán hàng POS $maDon',
        );
        await _cashbookRepo.saveTransaction(phieuThu);
      } else if (paymentMethod == 'HON_HOP') {
        // Thanh toán hỗn hợp: tách riêng phiếu thu tiền mặt và chuyển khoản
        if (cashAmount > 0) {
          final maPT1 = "PT${now.millisecondsSinceEpoch.toString().substring(6)}A";
          final phieuThuTienMat = CashbookModel(
            maPhieu: maPT1,
            chiNhanh: branch,
            loaiPhieu: 'THU',
            loaiQuy: 'TIEN_MAT',
            ngayGD: now,
            soTien: cashAmount,
            doiTuong: 'Khách hàng',
            maDoiTuong: _selectedCustomer?.maDoiTac ?? 'KHACHLE',
            maChungTu: maDon,
            ghiChu: 'Thu tiền mặt đơn hàng $maDon (Thanh toán hỗn hợp)',
          );
          await _cashbookRepo.saveTransaction(phieuThuTienMat);
        }
        if (bankTransferAmount > 0) {
          final maPT2 = "PT${now.millisecondsSinceEpoch.toString().substring(6)}B";
          final phieuThuBank = CashbookModel(
            maPhieu: maPT2,
            chiNhanh: branch,
            loaiPhieu: 'THU',
            loaiQuy: bankName ?? 'TAI_KHOAN',
            ngayGD: now,
            soTien: bankTransferAmount,
            doiTuong: 'Khách hàng',
            maDoiTuong: _selectedCustomer?.maDoiTac ?? 'KHACHLE',
            maChungTu: maDon,
            ghiChu: 'Thu chuyển khoản đơn hàng $maDon (Thanh toán hỗn hợp)',
          );
          await _cashbookRepo.saveTransaction(phieuThuBank);
        }
      }

      // 4. Trừ tồn kho sản phẩm
      for (final item in _cart) {
        final prod = _allProducts.firstWhere(
          (p) => p.maHang == item.maHang, 
          orElse: () => ProductModel(maHang: item.maHang, tenHang: item.tenHang),
        );
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
