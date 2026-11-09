import 'order_model.dart';

class StockAuditItemModel {
  final String maHang;
  final String tenHang;
  final String dvt;
  final int tonSoSach;
  final int tonThucTe;
  final int slChenhLech;
  final double donGia;
  final double giaTriChenhLech;

  StockAuditItemModel({
    required this.maHang,
    required this.tenHang,
    this.dvt = 'Cái',
    this.tonSoSach = 0,
    this.tonThucTe = 0,
    int? slChenhLech,
    this.donGia = 0,
    double? giaTriChenhLech,
  })  : slChenhLech = slChenhLech ?? (tonThucTe - tonSoSach),
        giaTriChenhLech = giaTriChenhLech ?? ((tonThucTe - tonSoSach) * donGia);

  factory StockAuditItemModel.fromJson(Map<String, dynamic> json) {
    int soSach = 0;
    final rawSoSach = json['tonSoSach'] ?? json['slHeThong'] ?? json['ton_so_sach'] ?? json['so_sach'];
    if (rawSoSach is num) {
      soSach = rawSoSach.toInt();
    } else if (rawSoSach != null) {
      soSach = int.tryParse(rawSoSach.toString().split('.')[0]) ?? 0;
    }

    int thucTe = 0;
    final rawThucTe = json['tonThucTe'] ?? json['slThucTe'] ?? json['ton_thuc_te'] ?? json['thuc_te'];
    if (rawThucTe is num) {
      thucTe = rawThucTe.toInt();
    } else if (rawThucTe != null) {
      thucTe = int.tryParse(rawThucTe.toString().split('.')[0]) ?? 0;
    }

    int chenhLech = thucTe - soSach;
    final rawChenhLech = json['slChenhLech'] ?? json['chenhLech'] ?? json['sl_chenh_lech'];
    if (rawChenhLech is num) {
      chenhLech = rawChenhLech.toInt();
    } else if (rawChenhLech != null) {
      chenhLech = int.tryParse(rawChenhLech.toString().split('.')[0]) ?? chenhLech;
    }

    double price = 0.0;
    final rawPrice = json['donGia'] ?? json['giaVon'] ?? json['don_gia'] ?? json['gia_von'];
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice != null) {
      price = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    double giaTriLech = chenhLech * price;
    final rawGiaTri = json['giaTriChenhLech'] ?? json['gia_tri_chenh_lech'];
    if (rawGiaTri is num) {
      giaTriLech = rawGiaTri.toDouble();
    } else if (rawGiaTri != null) {
      giaTriLech = double.tryParse(rawGiaTri.toString()) ?? giaTriLech;
    }

    return StockAuditItemModel(
      maHang: json['maHang']?.toString() ?? json['ma_hang']?.toString() ?? '',
      tenHang: json['tenHang']?.toString() ?? json['ten_hang']?.toString() ?? '',
      dvt: json['dvt']?.toString() ?? 'Cái',
      tonSoSach: soSach,
      tonThucTe: thucTe,
      slChenhLech: chenhLech,
      donGia: price,
      giaTriChenhLech: giaTriLech,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maHang': maHang,
      'tenHang': tenHang,
      'dvt': dvt,
      'tonSoSach': tonSoSach,
      'tonThucTe': tonThucTe,
      'slChenhLech': slChenhLech,
      'donGia': donGia,
      'giaTriChenhLech': giaTriChenhLech,
    };
  }
}

class StockAuditModel {
  final String maKiemKho;
  final DateTime thoiGian;
  final DateTime? ngayCanBang;
  final String chiNhanh;
  final String ghiChu;
  final String trangThai; // 'Phiếu tạm', 'Đã cân bằng kho', 'Đã hủy'
  final int tongSoLuongThucTe;
  final int tongSoLuongLech;
  final double tongGiaTriChenhLech;
  final List<StockAuditItemModel> chiTiet;

  StockAuditModel({
    required this.maKiemKho,
    DateTime? thoiGian,
    this.ngayCanBang,
    this.chiNhanh = 'CN01: Trụ sở chính Thanh Miện',
    this.ghiChu = '',
    this.trangThai = 'Đã cân bằng kho',
    int? tongSoLuongThucTe,
    int? tongSoLuongLech,
    double? tongGiaTriChenhLech,
    this.chiTiet = const [],
  })  : thoiGian = thoiGian ?? DateTime.now(),
        tongSoLuongThucTe = tongSoLuongThucTe ?? chiTiet.fold(0, (sum, i) => sum + i.tonThucTe),
        tongSoLuongLech = tongSoLuongLech ?? chiTiet.fold(0, (sum, i) => sum + i.slChenhLech),
        tongGiaTriChenhLech = tongGiaTriChenhLech ?? chiTiet.fold(0.0, (sum, i) => sum + i.giaTriChenhLech);

  bool get canBalance => trangThai == 'Phiếu tạm';
  bool get canEdit => trangThai == 'Phiếu tạm';
  bool get canCancel => trangThai != 'Đã hủy';

  factory StockAuditModel.fromJson(Map<String, dynamic> json) {
    final thoiGianParsed = OrderModel.parseCustomDate(
      json['thoiGian'] ?? json['thoi_gian'] ?? json['ngayKiem'] ?? json['ngay_kiem'] ?? json['ngayTao'],
    );
    DateTime? ngayCanBangParsed;
    final rawCanBang = json['ngayCanBang'] ?? json['ngay_can_bang'];
    if (rawCanBang != null && rawCanBang.toString().isNotEmpty) {
      ngayCanBangParsed = OrderModel.parseCustomDate(rawCanBang);
    }

    List<StockAuditItemModel> items = [];
    final rawItems = json['sanPham'] ?? json['chiTiet'] ?? json['chiTietSanPham'] ?? json['danhSachSanPham'];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map) {
          try {
            items.add(StockAuditItemModel.fromJson(Map<String, dynamic>.from(it)));
          } catch (_) {}
        }
      }
    }

    int slThucTe = items.fold(0, (sum, i) => sum + i.tonThucTe);
    final rawSlTT = json['tongSoLuongThucTe'] ?? json['tong_sl_thuc_te'];
    if (rawSlTT is num) {
      slThucTe = rawSlTT.toInt();
    } else if (rawSlTT != null) {
      slThucTe = int.tryParse(rawSlTT.toString()) ?? slThucTe;
    }

    int slLech = items.fold(0, (sum, i) => sum + i.slChenhLech);
    final rawSlLech = json['tongSoLuongLech'] ?? json['tong_sl_lech'] ?? json['tongChenhLech'];
    if (rawSlLech is num) {
      slLech = rawSlLech.toInt();
    } else if (rawSlLech != null) {
      slLech = int.tryParse(rawSlLech.toString()) ?? slLech;
    }

    double giaTriLech = items.fold(0.0, (sum, i) => sum + i.giaTriChenhLech);
    final rawGTL = json['tongGiaTriChenhLech'] ?? json['tong_gia_tri_chenh_lech'];
    if (rawGTL is num) {
      giaTriLech = rawGTL.toDouble();
    } else if (rawGTL != null) {
      giaTriLech = double.tryParse(rawGTL.toString()) ?? giaTriLech;
    }

    return StockAuditModel(
      maKiemKho: json['maKiemKho']?.toString() ?? json['ma_kiem_kho']?.toString() ?? json['maPhieu']?.toString() ?? '',
      thoiGian: thoiGianParsed,
      ngayCanBang: ngayCanBangParsed,
      chiNhanh: json['chiNhanh']?.toString() ?? json['chi_nhanh']?.toString() ?? 'CN01: Trụ sở chính Thanh Miện',
      ghiChu: json['ghiChu']?.toString() ?? json['ghi_chu']?.toString() ?? '',
      trangThai: json['trangThai']?.toString() ?? json['trang_thai']?.toString() ?? 'Đã cân bằng kho',
      tongSoLuongThucTe: slThucTe,
      tongSoLuongLech: slLech,
      tongGiaTriChenhLech: giaTriLech,
      chiTiet: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maKiemKho': maKiemKho,
      'thoiGian': thoiGian.toIso8601String(),
      'ngayCanBang': ngayCanBang?.toIso8601String(),
      'chiNhanh': chiNhanh,
      'ghiChu': ghiChu,
      'trangThai': trangThai,
      'tongSoLuongThucTe': tongSoLuongThucTe,
      'tongSoLuongLech': tongSoLuongLech,
      'tongGiaTriChenhLech': tongGiaTriChenhLech,
      'sanPham': chiTiet.map((e) => e.toJson()).toList(),
    };
  }
}
