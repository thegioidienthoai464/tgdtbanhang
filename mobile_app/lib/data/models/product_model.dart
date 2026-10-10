class ProductModel {
  final int? id;
  final String maHang;
  final String tenHang;
  final String maNhom;
  final String donViTinh;
  final double giaVon;
  final double giaBan;
  final bool coQuanLyImei;
  final double tonKho;
  final String trangThai;
  final String chiNhanh;

  /// Bản đồ số lượng tồn kho theo từng chi nhánh: {'CN01': 10, 'CN02': 5, 'CN03': 3, 'CN04': 0}
  final Map<String, double> tonKhoTheoChiNhanh;

  /// Bản đồ giá vốn theo từng chi nhánh: {'CN01': 9500000, 'CN02': 9600000, ...}
  final Map<String, double> giaVonTheoChiNhanh;

  /// Bản đồ danh sách IMEI theo từng chi nhánh: {'CN01': ['IMEI1', 'IMEI2'], ...}
  final Map<String, List<String>> imeiTheoChiNhanh;

  ProductModel({
    this.id,
    required this.maHang,
    required this.tenHang,
    this.maNhom = '',
    this.donViTinh = 'Cái',
    this.giaVon = 0,
    this.giaBan = 0,
    this.coQuanLyImei = false,
    this.tonKho = 0,
    this.trangThai = 'Kinh doanh',
    this.chiNhanh = 'CN01: Trụ sở chính',
    this.tonKhoTheoChiNhanh = const {},
    this.giaVonTheoChiNhanh = const {},
    this.imeiTheoChiNhanh = const {},
  });

  ProductModel copyWith({
    int? id,
    String? maHang,
    String? tenHang,
    String? maNhom,
    String? donViTinh,
    double? giaVon,
    double? giaBan,
    bool? coQuanLyImei,
    double? tonKho,
    String? trangThai,
    String? chiNhanh,
    Map<String, double>? tonKhoTheoChiNhanh,
    Map<String, double>? giaVonTheoChiNhanh,
    Map<String, List<String>>? imeiTheoChiNhanh,
  }) {
    return ProductModel(
      id: id ?? this.id,
      maHang: maHang ?? this.maHang,
      tenHang: tenHang ?? this.tenHang,
      maNhom: maNhom ?? this.maNhom,
      donViTinh: donViTinh ?? this.donViTinh,
      giaVon: giaVon ?? this.giaVon,
      giaBan: giaBan ?? this.giaBan,
      coQuanLyImei: coQuanLyImei ?? this.coQuanLyImei,
      tonKho: tonKho ?? this.tonKho,
      trangThai: trangThai ?? this.trangThai,
      chiNhanh: chiNhanh ?? this.chiNhanh,
      tonKhoTheoChiNhanh: tonKhoTheoChiNhanh ?? this.tonKhoTheoChiNhanh,
      giaVonTheoChiNhanh: giaVonTheoChiNhanh ?? this.giaVonTheoChiNhanh,
      imeiTheoChiNhanh: imeiTheoChiNhanh ?? this.imeiTheoChiNhanh,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int?,
      maHang: json['ma_hang']?.toString() ?? '',
      tenHang: json['ten_hang']?.toString() ?? '',
      maNhom: json['ma_nhom']?.toString() ?? '',
      donViTinh: json['don_vi_tinh']?.toString() ?? 'Cái',
      giaVon: (json['gia_von'] as num?)?.toDouble() ?? 0.0,
      giaBan: (json['gia_ban'] as num?)?.toDouble() ?? 0.0,
      coQuanLyImei: json['co_quan_ly_imei'] == true || json['co_quan_ly_imei'] == 'true',
      tonKho: (json['ton_kho'] as num?)?.toDouble() ?? 0.0,
      trangThai: json['trang_thai']?.toString() ?? 'Kinh doanh',
      chiNhanh: json['chi_nhanh']?.toString() ?? 'CN01: Trụ sở chính',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_hang': maHang,
      'ten_hang': tenHang,
      'ma_nhom': maNhom,
      'don_vi_tinh': donViTinh,
      'gia_von': giaVon,
      'gia_ban': giaBan,
      'co_quan_ly_imei': coQuanLyImei,
      'ton_kho': tonKho,
      'trang_thai': trangThai,
      'chi_nhanh': chiNhanh,
    };
  }

  /// Chuẩn hóa chuỗi tên chi nhánh hoặc mã chi nhánh về mã chuẩn: 'CN01', 'CN02', 'CN03', 'CN04'
  static String normalizeBranchCode(String? str) {
    if (str == null || str.isEmpty) return 'CN01';
    final s = str.trim().toUpperCase();
    if (s.startsWith('CN01')) return 'CN01';
    if (s.startsWith('CN02')) return 'CN02';
    if (s.startsWith('CN03')) return 'CN03';
    if (s.startsWith('CN04')) return 'CN04';
    if (s.contains('THANH MIỆN') || s.contains('THANH MIEN') || s.contains('TRỤ SỞ') || s.contains('TRU SO')) return 'CN01';
    if (s.contains('THANH GIANG')) return 'CN02';
    if (s.contains('BÌNH GIANG') || s.contains('BINH GIANG')) return 'CN03';
    if (s.contains('ONLINE')) return 'CN04';
    return 'CN01';
  }

  /// Lấy tồn kho của sản phẩm tại một chi nhánh cụ thể (hoặc Toàn hệ thống nếu ALL)
  double getTonKhoTaiChiNhanh(String maCN) {
    if (maCN.toUpperCase() == 'ALL') {
      return getTongTonKhoToanHeThong();
    }
    final code = normalizeBranchCode(maCN);
    if (tonKhoTheoChiNhanh.containsKey(code)) {
      return tonKhoTheoChiNhanh[code] ?? 0.0;
    }
    if (normalizeBranchCode(chiNhanh) == code) {
      return tonKho;
    }
    return 0.0;
  }

  /// Lấy tổng tồn kho của toàn bộ hệ thống (tất cả chi nhánh cộng lại)
  double getTongTonKhoToanHeThong() {
    if (tonKhoTheoChiNhanh.isNotEmpty) {
      return tonKhoTheoChiNhanh.values.fold(0.0, (sum, v) => sum + v);
    }
    return tonKho;
  }

  /// Lấy số lượng tồn kho phù hợp với bộ lọc chi nhánh đang chọn
  double getTonKhoChoBoLoc(Set<String> selectedCodes, [bool isAllSelected = false]) {
    if (isAllSelected || selectedCodes.contains('ALL') || selectedCodes.isEmpty) {
      return getTongTonKhoToanHeThong();
    }
    double total = 0.0;
    for (final code in selectedCodes) {
      total += getTonKhoTaiChiNhanh(code);
    }
    return total;
  }

  /// Lấy giá vốn theo chi nhánh
  double getGiaVonTaiChiNhanh(String maCN) {
    if (maCN.toUpperCase() == 'ALL') return giaVon;
    final code = normalizeBranchCode(maCN);
    if (giaVonTheoChiNhanh.containsKey(code) && (giaVonTheoChiNhanh[code] ?? 0) > 0) {
      return giaVonTheoChiNhanh[code]!;
    }
    return giaVon;
  }

  /// Lấy danh sách IMEI còn tồn tại chi nhánh cụ thể
  List<String> getImeisTaiChiNhanh(String maCN) {
    if (maCN.toUpperCase() == 'ALL') {
      return imeiTheoChiNhanh.values.expand((list) => list).toList();
    }
    final code = normalizeBranchCode(maCN);
    return imeiTheoChiNhanh[code] ?? [];
  }
}
