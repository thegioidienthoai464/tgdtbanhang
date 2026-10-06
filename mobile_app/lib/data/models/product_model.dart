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
  });

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
}
