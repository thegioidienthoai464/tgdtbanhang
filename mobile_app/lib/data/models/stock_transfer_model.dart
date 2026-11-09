import 'order_model.dart';

class StockTransferItemModel {
  final String maHang;
  final String tenHang;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final List<String> imeiList;

  StockTransferItemModel({
    required this.maHang,
    required this.tenHang,
    this.soLuong = 1,
    this.donGia = 0,
    double? thanhTien,
    this.imeiList = const [],
  }) : thanhTien = thanhTien ?? (soLuong * donGia);

  factory StockTransferItemModel.fromJson(Map<String, dynamic> json) {
    int qty = 1;
    final rawQty = json['soLuong'] ?? json['so_luong'] ?? json['sl'];
    if (rawQty is num) {
      qty = rawQty.toInt();
    } else if (rawQty != null) {
      qty = int.tryParse(rawQty.toString().split('.')[0]) ?? 1;
    }

    double price = 0.0;
    final rawPrice = json['donGia'] ?? json['don_gia'] ?? json['giaNhap'] ?? json['gia_nhap'];
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice != null) {
      price = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    double total = qty * price;
    final rawTotal = json['thanhTien'] ?? json['thanh_tien'] ?? json['giaTri'];
    if (rawTotal is num) {
      total = rawTotal.toDouble();
    } else if (rawTotal != null) {
      total = double.tryParse(rawTotal.toString()) ?? total;
    }

    List<String> imeis = [];
    final rawImei = json['imeiList'] ?? json['danhSachImei'] ?? json['imei'];
    if (rawImei is List) {
      imeis = rawImei.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (rawImei is String && rawImei.isNotEmpty) {
      imeis = rawImei.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (json['imeiStr'] != null && json['imeiStr'].toString().isNotEmpty) {
      imeis = json['imeiStr'].toString().split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return StockTransferItemModel(
      maHang: json['maHang']?.toString() ?? json['ma_hang']?.toString() ?? '',
      tenHang: json['tenHang']?.toString() ?? json['ten_hang']?.toString() ?? '',
      soLuong: qty,
      donGia: price,
      thanhTien: total,
      imeiList: imeis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maHang': maHang,
      'tenHang': tenHang,
      'soLuong': soLuong,
      'donGia': donGia,
      'thanhTien': thanhTien,
      'imeiList': imeiList,
      'imeiStr': imeiList.join(', '),
    };
  }
}

class StockTransferModel {
  final String maPhieu;
  final String tuChiNhanh;
  final String toiChiNhanh;
  final String cnXuat;
  final String cnNhan;
  final DateTime ngayChuyen;
  final DateTime? ngayNhan;
  final String nguoiTao;
  final String ghiChu;
  final String trangThai; // 'Phiếu tạm', 'Đang chuyển', 'Đã nhận', 'Đã hủy'
  final int tongSoLuong;
  final double tongTien;
  final List<StockTransferItemModel> chiTiet;

  StockTransferModel({
    required this.maPhieu,
    this.tuChiNhanh = 'CN01: Trụ sở chính Thanh Miện',
    this.toiChiNhanh = 'CN02: Chi nhánh Thanh Giang',
    String? cnXuat,
    String? cnNhan,
    DateTime? ngayChuyen,
    this.ngayNhan,
    this.nguoiTao = 'Quản trị viên',
    this.ghiChu = '',
    this.trangThai = 'Đang chuyển',
    int? tongSoLuong,
    double? tongTien,
    this.chiTiet = const [],
  })  : cnXuat = cnXuat ?? _extractBranchCode(tuChiNhanh),
        cnNhan = cnNhan ?? _extractBranchCode(toiChiNhanh),
        ngayChuyen = ngayChuyen ?? DateTime.now(),
        tongSoLuong = tongSoLuong ?? chiTiet.fold(0, (sum, i) => sum + i.soLuong),
        tongTien = tongTien ?? chiTiet.fold(0.0, (sum, i) => sum + i.thanhTien);

  static String _extractBranchCode(String branchStr) {
    if (branchStr.contains(':')) {
      return branchStr.split(':').first.trim().toUpperCase();
    }
    final match = RegExp(r'(CN\d+)', caseSensitive: false).firstMatch(branchStr);
    return match != null ? match.group(1)!.toUpperCase() : 'CN01';
  }

  bool isDestinationBranch(String currentBranchCode) {
    final cur = currentBranchCode.toUpperCase();
    if (cur == 'ALL') return true;
    return cnNhan.toUpperCase() == cur || toiChiNhanh.toUpperCase().contains(cur);
  }

  bool isSourceBranch(String currentBranchCode) {
    final cur = currentBranchCode.toUpperCase();
    if (cur == 'ALL') return true;
    return cnXuat.toUpperCase() == cur || tuChiNhanh.toUpperCase().contains(cur);
  }

  bool isRelatedToBranch(String currentBranchCode) {
    if (currentBranchCode.toUpperCase() == 'ALL') return true;
    return isSourceBranch(currentBranchCode) || isDestinationBranch(currentBranchCode);
  }

  bool canReceive(String currentBranchCode) {
    if (trangThai == 'Đã nhận' || trangThai == 'Đã hủy') return false;
    return isDestinationBranch(currentBranchCode) || currentBranchCode.toUpperCase() == 'ALL';
  }

  bool get canEdit => trangThai == 'Phiếu tạm' || trangThai == 'Đang chuyển';
  bool get canCancel => trangThai != 'Đã hủy';

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    final ngayChuyenParsed = OrderModel.parseCustomDate(
      json['ngayChuyen'] ?? json['ngay_chuyen'] ?? json['ngayTao'] ?? json['thoiGian'],
    );
    DateTime? ngayNhanParsed;
    final rawNgayNhan = json['ngayNhan'] ?? json['ngay_nhan'];
    if (rawNgayNhan != null && rawNgayNhan.toString().isNotEmpty) {
      ngayNhanParsed = OrderModel.parseCustomDate(rawNgayNhan);
    }

    final fromBranch = json['tuChiNhanh']?.toString() ??
        json['tenCnXuat']?.toString() ??
        json['chiNhanhXuat']?.toString() ??
        json['cnXuat']?.toString() ??
        'CN01: Trụ sở chính Thanh Miện';

    final toBranch = json['toiChiNhanh']?.toString() ??
        json['tenCnNhan']?.toString() ??
        json['chiNhanhNhan']?.toString() ??
        json['cnNhan']?.toString() ??
        'CN02: Chi nhánh Thanh Giang';

    List<StockTransferItemModel> items = [];
    final rawItems = json['chiTietSanPham'] ?? json['chiTiet'] ?? json['danhSachSanPham'] ?? json['sanPham'];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map) {
          try {
            items.add(StockTransferItemModel.fromJson(Map<String, dynamic>.from(it)));
          } catch (_) {}
        }
      }
    }

    int sl = items.fold(0, (sum, i) => sum + i.soLuong);
    final rawSl = json['tongSoLuong'] ?? json['tong_so_luong'];
    if (rawSl is num) {
      sl = rawSl.toInt();
    } else if (rawSl != null) {
      sl = int.tryParse(rawSl.toString()) ?? sl;
    }

    double tien = items.fold(0.0, (sum, i) => sum + i.thanhTien);
    final rawTien = json['tongTien'] ?? json['tong_tien'] ?? json['tongGiaTri'];
    if (rawTien is num) {
      tien = rawTien.toDouble();
    } else if (rawTien != null) {
      tien = double.tryParse(rawTien.toString()) ?? tien;
    }

    return StockTransferModel(
      maPhieu: json['maPhieu']?.toString() ?? json['ma_phieu']?.toString() ?? '',
      tuChiNhanh: fromBranch,
      toiChiNhanh: toBranch,
      cnXuat: json['cnXuat']?.toString() ?? _extractBranchCode(fromBranch),
      cnNhan: json['cnNhan']?.toString() ?? _extractBranchCode(toBranch),
      ngayChuyen: ngayChuyenParsed,
      ngayNhan: ngayNhanParsed,
      nguoiTao: json['nguoiTao']?.toString() ?? json['nguoiLap']?.toString() ?? json['nhanVien']?.toString() ?? 'Quản trị viên',
      ghiChu: json['ghiChu']?.toString() ?? json['ghi_chu']?.toString() ?? '',
      trangThai: json['trangThai']?.toString() ?? json['trang_thai']?.toString() ?? 'Đang chuyển',
      tongSoLuong: sl,
      tongTien: tien,
      chiTiet: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maPhieu': maPhieu,
      'tuChiNhanh': tuChiNhanh,
      'toiChiNhanh': toiChiNhanh,
      'cnXuat': cnXuat,
      'cnNhan': cnNhan,
      'ngayChuyen': ngayChuyen.toIso8601String(),
      'ngayNhan': ngayNhan?.toIso8601String(),
      'nguoiTao': nguoiTao,
      'ghiChu': ghiChu,
      'trangThai': trangThai,
      'tongSoLuong': tongSoLuong,
      'tongTien': tongTien,
      'chiTietSanPham': chiTiet.map((e) => e.toJson()).toList(),
    };
  }
}
