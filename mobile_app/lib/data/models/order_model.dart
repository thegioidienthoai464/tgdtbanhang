class OrderItemModel {
  final String maHang;
  final String tenHang;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final String imeiStr;

  OrderItemModel({
    required this.maHang,
    required this.tenHang,
    this.soLuong = 1,
    this.donGia = 0,
    double? thanhTien,
    this.imeiStr = '',
  }) : thanhTien = thanhTien ?? (soLuong * donGia);

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    int qty = (json['soLuong'] ?? json['so_luong'] ?? 1) as int;
    double price = ((json['donGia'] ?? json['don_gia'] ?? json['giaNhap']) as num?)?.toDouble() ?? 0.0;
    double total = ((json['thanhTien'] ?? json['thanh_tien']) as num?)?.toDouble() ?? (qty * price);

    return OrderItemModel(
      maHang: json['maHang']?.toString() ?? json['ma_hang']?.toString() ?? '',
      tenHang: json['tenHang']?.toString() ?? json['ten_hang']?.toString() ?? '',
      soLuong: qty,
      donGia: price,
      thanhTien: total,
      imeiStr: json['imeiStr']?.toString() ?? json['imei']?.toString() ?? '',
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
    this.maKH = 'KL',
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

  bool get isPreOrder => maDonHang.startsWith('DDH');
  bool get isImportOrder => maDonHang.startsWith('PNH');
  bool get isPosSale => !isPreOrder && !isImportOrder;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['ngay_ban'] != null 
          ? DateTime.parse(json['ngay_ban'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    List<OrderItemModel> items = [];
    if (json['chi_tiet_san_pham'] != null && json['chi_tiet_san_pham'] is List) {
      items = (json['chi_tiet_san_pham'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      maDonHang: json['ma_don_hang']?.toString() ?? '',
      ngayBan: parsedDate,
      maKH: json['ma_kh']?.toString() ?? 'KL',
      tenKH: json['ten_kh']?.toString() ?? 'Khách lẻ',
      soDienThoai: json['so_dien_thoai']?.toString() ?? '',
      chiNhanh: json['chi_nhanh']?.toString() ?? 'CN01: Trụ sở chính',
      tongTien: (json['tong_tien'] as num?)?.toDouble() ?? 0.0,
      giamGia: (json['giam_gia'] as num?)?.toDouble() ?? 0.0,
      khachPhaiTra: (json['khach_phai_tra'] as num?)?.toDouble() ?? 0.0,
      khachTra: (json['khach_tra'] as num?)?.toDouble() ?? 0.0,
      hinhThucTT: json['hinh_thuc_tt']?.toString() ?? 'TIEN_MAT',
      nganHangNhan: json['ngan_hang_nhan']?.toString(),
      chiTietSanPham: items,
      trangThai: json['trang_thai']?.toString() ?? 'Hoàn thành',
      nhanVien: json['nhan_vien']?.toString() ?? 'Quản trị viên',
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
