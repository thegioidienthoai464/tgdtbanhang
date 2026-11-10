class OrderItemModel {
  final String maHang;
  final String tenHang;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final String imeiStr;
  final bool coQuanLyImei;

  OrderItemModel({
    required this.maHang,
    required this.tenHang,
    this.soLuong = 1,
    this.donGia = 0,
    double? thanhTien,
    this.imeiStr = '',
    this.coQuanLyImei = true,
  }) : thanhTien = thanhTien ?? (soLuong * donGia);

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    int qty = 1;
    final rawQty = json['soLuong'] ?? json['so_luong'];
    if (rawQty is num) {
      qty = rawQty.toInt();
    } else if (rawQty != null) {
      qty = int.tryParse(rawQty.toString().split('.')[0]) ?? 1;
    }

    double price = 0.0;
    final rawPrice = json['donGia'] ?? json['don_gia'] ?? json['giaNhap'];
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice != null) {
      price = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    double total = qty * price;
    final rawTotal = json['thanhTien'] ?? json['thanh_tien'];
    if (rawTotal is num) {
      total = rawTotal.toDouble();
    } else if (rawTotal != null) {
      total = double.tryParse(rawTotal.toString()) ?? total;
    }

    final rawCoImei = json['coQuanLyImei'] ?? json['co_quan_ly_imei'] ?? json['coQuanLyIMEI'];
    bool hasImei = true;
    if (rawCoImei != null) {
      hasImei = rawCoImei == true ||
          rawCoImei.toString().toLowerCase() == 'true' ||
          rawCoImei.toString() == '1' ||
          rawCoImei.toString().toLowerCase() == 't';
    } else {
      final tenLower = (json['tenHang'] ?? json['ten_hang'] ?? '').toString().toLowerCase();
      final bool isAccessory = tenLower.contains('ốp') ||
          tenLower.contains('kính') ||
          tenLower.contains('cường lực') ||
          tenLower.contains('dán') ||
          tenLower.contains('bao da') ||
          tenLower.contains('tai nghe') ||
          tenLower.contains('sạc') ||
          tenLower.contains('cáp');
      if (isAccessory) {
        hasImei = false;
      }
    }

    return OrderItemModel(
      maHang: json['maHang']?.toString() ?? json['ma_hang']?.toString() ?? '',
      tenHang: json['tenHang']?.toString() ?? json['ten_hang']?.toString() ?? '',
      soLuong: qty,
      donGia: price,
      thanhTien: total,
      imeiStr: json['imeiStr']?.toString() ?? json['imei']?.toString() ?? '',
      coQuanLyImei: hasImei,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maHang': maHang,
      'tenHang': tenHang,
      'soLuong': soLuong,
      'donGia': donGia,
      'thanhTien': thanhTien,
      'imeiStr': imeiStr,
      'coQuanLyImei': coQuanLyImei,
      'co_quan_ly_imei': coQuanLyImei,
    };
  }
}

class OrderModel {
  final String maDonHang;
  final DateTime ngayBan;
  final String maKH;
  final String tenKH;
  final String soDienThoai;
  final String chiNhanh;
  final double tongTien;
  final double giamGia;
  final double khachPhaiTra;
  final double khachTra;
  final String hinhThucTT;
  final String? nganHangNhan;
  final List<OrderItemModel> chiTietSanPham;
  final String trangThai;
  final String nhanVien;

  OrderModel({
    required this.maDonHang,
    DateTime? ngayBan,
    this.maKH = 'KHACHLE',
    this.tenKH = 'Khách lẻ',
    this.soDienThoai = '',
    this.chiNhanh = 'CN01: Trụ sở chính',
    this.tongTien = 0,
    this.giamGia = 0,
    this.khachPhaiTra = 0,
    this.khachTra = 0,
    this.hinhThucTT = 'TIEN_MAT',
    this.nganHangNhan,
    this.chiTietSanPham = const [],
    this.trangThai = 'Hoàn thành',
    this.nhanVien = 'Quản trị viên',
  }) : ngayBan = ngayBan ?? DateTime.now();

  bool get isPreOrder => maDonHang.startsWith('DDH') || maDonHang.startsWith('DH');
  bool get isImportOrder => maDonHang.startsWith('PNH') || maDonHang.startsWith('PN');
  bool get isPosSale => !isPreOrder && !isImportOrder;
  double get conNo => (khachPhaiTra - khachTra).clamp(0.0, 999999999999.0);

  static DateTime parseCustomDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString().trim();
    if (str.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(str);
    } catch (_) {}

    final parts = str.split(' ');
    final dateParts = parts[0].split(RegExp(r'[/.-]'));
    if (dateParts.length == 3) {
      final day = int.tryParse(dateParts[0]) ?? 1;
      final month = int.tryParse(dateParts[1]) ?? 1;
      final year = int.tryParse(dateParts[2]) ?? 2026;
      int hour = 0, min = 0, sec = 0;
      if (parts.length > 1) {
        final timeParts = parts[1].split(':');
        if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? 0;
        if (timeParts.length > 1) min = int.tryParse(timeParts[1]) ?? 0;
        if (timeParts.length > 2) sec = int.tryParse(timeParts[2]) ?? 0;
      }
      return DateTime(year, month, day, hour, min, sec);
    }
    return DateTime.now();
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final parsedDate = parseCustomDate(
      json['ngay_ban'] ?? json['ngayBan'] ?? json['ngayNhap'] ?? json['ngay_nhap'] ?? json['thoiGian'],
    );

    List<OrderItemModel> items = [];
    final rawItems = json['chi_tiet_san_pham'] ?? json['chiTietSanPham'] ?? json['danhSachSanPham'] ?? json['sanPham'];
    if (rawItems != null && rawItems is List) {
      for (final i in rawItems) {
        if (i is Map) {
          try {
            items.add(OrderItemModel.fromJson(Map<String, dynamic>.from(i)));
          } catch (_) {}
        }
      }
    }

    double getSafeDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) return double.tryParse(val.toString()) ?? 0.0;
      return 0.0;
    }

    final total = getSafeDouble(json['tong_tien'] ?? json['tongTien']);
    final discount = getSafeDouble(json['giam_gia'] ?? json['giamGia']);
    final mustPay = getSafeDouble(json['khach_phai_tra'] ?? json['khachPhaiTra'] ?? (total - discount));
    final paid = getSafeDouble(
      json['khach_tra'] ?? json['khachTra'] ?? json['khachDaTra'] ?? json['daTra'] ?? json['da_tra'],
    );

    final maDon = json['ma_don_hang']?.toString() ??
        json['maDonHang']?.toString() ??
        json['maDon']?.toString() ??
        json['ma_don']?.toString() ??
        json['ma_phieu']?.toString() ??
        json['maPhieu']?.toString() ??
        '';

    final maDoiTac = json['ma_kh']?.toString() ??
        json['maKH']?.toString() ??
        json['ma_ncc']?.toString() ??
        json['maNCC']?.toString() ??
        'KHACHLE';

    final tenDoiTac = json['ten_kh']?.toString() ??
        json['tenKH']?.toString() ??
        json['ten_ncc']?.toString() ??
        json['tenNCC']?.toString() ??
        (maDon.startsWith('PN') ? 'Nhà cung cấp' : 'Khách lẻ');

    final phone = json['so_dien_thoai']?.toString() ??
        json['soDienThoai']?.toString() ??
        json['dienThoai']?.toString() ??
        '';

    final branch = json['chi_nhanh']?.toString() ??
        json['chiNhanh']?.toString() ??
        'CN02: Chi nhánh Thanh Giang';

    return OrderModel(
      maDonHang: maDon,
      ngayBan: parsedDate,
      maKH: maDoiTac,
      tenKH: tenDoiTac,
      soDienThoai: phone,
      chiNhanh: branch,
      tongTien: total,
      giamGia: discount,
      khachPhaiTra: mustPay,
      khachTra: paid,
      hinhThucTT: json['hinh_thuc_tt']?.toString() ?? json['hinhThucTT']?.toString() ?? 'TIEN_MAT',
      nganHangNhan: json['ngan_hang_nhan']?.toString() ?? json['nganHangNhan']?.toString(),
      chiTietSanPham: items,
      trangThai: json['trang_thai']?.toString() ?? json['trangThai']?.toString() ?? 'Hoàn thành',
      nhanVien: json['nhan_vien']?.toString() ?? json['nhanVien']?.toString() ?? json['nguoiBan']?.toString() ?? json['nguoiNhap']?.toString() ?? 'Quản trị viên',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_don_hang': maDonHang,
      'ngay_ban': ngayBan.toIso8601String(),
      'ma_kh': maKH,
      'ten_kh': tenKH,
      'so_dien_thoai': soDienThoai,
      'chi_nhanh': chiNhanh,
      'tong_tien': tongTien,
      'giam_gia': giamGia,
      'khach_phai_tra': khachPhaiTra,
      'khach_tra': khachTra,
      'hinh_thuc_tt': hinhThucTT,
      'ngan_hang_nhan': nganHangNhan,
      'chi_tiet_san_pham': chiTietSanPham.map((e) => e.toJson()).toList(),
      'trang_thai': trangThai,
      'nhan_vien': nhanVien,
    };
  }
}
