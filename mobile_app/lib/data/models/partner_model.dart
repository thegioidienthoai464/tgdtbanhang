class PartnerModel {
  final String maDoiTac;
  final String loaiDoiTac; // 'KH' hoặc 'NCC'
  final String tenDoiTac;
  final String soDienThoai;
  final String diaChi;
  final double congNo;
  final String trangThai;

  PartnerModel({
    required this.maDoiTac,
    this.loaiDoiTac = 'KH',
    required this.tenDoiTac,
    this.soDienThoai = '',
    this.diaChi = '',
    this.congNo = 0,
    this.trangThai = 'HoatDong',
  });

  bool get isCustomer => loaiDoiTac == 'KH';
  bool get isSupplier => loaiDoiTac == 'NCC';

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      maDoiTac: json['ma_doi_tac']?.toString() ?? '',
      loaiDoiTac: json['loai_doi_tac']?.toString() ?? 'KH',
      tenDoiTac: json['ten_doi_tac']?.toString() ?? 'Khách lẻ',
      soDienThoai: json['so_dien_thoai']?.toString() ?? '',
      diaChi: json['dia_chi']?.toString() ?? '',
      congNo: (json['cong_no'] as num?)?.toDouble() ?? 0.0,
      trangThai: json['trang_thai']?.toString() ?? 'HoatDong',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_doi_tac': maDoiTac,
      'loai_doi_tac': loaiDoiTac,
      'ten_doi_tac': tenDoiTac,
      'so_dien_thoai': soDienThoai,
      'dia_chi': diaChi,
      'cong_no': congNo,
      'trang_thai': trangThai,
    };
  }
}
