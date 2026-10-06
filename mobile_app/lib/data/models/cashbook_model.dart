class CashbookModel {
  final String maPhieu;
  final String chiNhanh;
  final String loaiPhieu; // 'THU' hoặc 'CHI'
  final String loaiQuy;   // 'TIEN_MAT' hoặc 'TAI_KHOAN'
  final DateTime ngayGD;
  final double soTien;
  final String doiTuong;
  final String maDoiTuong;
  final String maChungTu;
  final String trangThai;
  final String ghiChu;

  CashbookModel({
    required this.maPhieu,
    this.chiNhanh = 'CN01: Trụ sở chính',
    this.loaiPhieu = 'THU',
    this.loaiQuy = 'TIEN_MAT',
    DateTime? ngayGD,
    this.soTien = 0,
    this.doiTuong = '',
    this.maDoiTuong = '',
    this.maChungTu = '',
    this.trangThai = 'DaThanhToan',
    this.ghiChu = '',
  }) : ngayGD = ngayGD ?? DateTime.now();

  bool get isIncome => loaiPhieu == 'THU';
  bool get isExpense => loaiPhieu == 'CHI';

  factory CashbookModel.fromJson(Map<String, dynamic> json) {
    DateTime dt;
    try {
      dt = json['ngay_gd'] != null ? DateTime.parse(json['ngay_gd'].toString()) : DateTime.now();
    } catch (_) {
      dt = DateTime.now();
    }

    return CashbookModel(
      maPhieu: json['ma_phieu']?.toString() ?? '',
      chiNhanh: json['chi_nhanh']?.toString() ?? 'CN01: Trụ sở chính',
      loaiPhieu: json['loai_phieu']?.toString() ?? 'THU',
      loaiQuy: json['loai_quy']?.toString() ?? 'TIEN_MAT',
      ngayGD: dt,
      soTien: (json['so_tien'] as num?)?.toDouble() ?? 0.0,
      doiTuong: json['doi_tuong']?.toString() ?? '',
      maDoiTuong: json['ma_doi_tuong']?.toString() ?? '',
      maChungTu: json['ma_chung_tu']?.toString() ?? '',
      trangThai: json['trang_thai']?.toString() ?? 'DaThanhToan',
      ghiChu: json['ghi_chu']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_phieu': maPhieu,
      'chi_nhanh': chiNhanh,
      'loai_phieu': loaiPhieu,
      'loai_quy': loaiQuy,
      'ngay_gd': ngayGD.toIso8601String(),
      'so_tien': soTien,
      'doi_tuong': doiTuong,
      'ma_doi_tuong': maDoiTuong,
      'ma_chung_tu': maChungTu,
      'trang_thai': trangThai,
      'ghi_chu': ghiChu,
    };
  }
}
