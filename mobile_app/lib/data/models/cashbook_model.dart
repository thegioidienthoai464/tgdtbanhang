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

  factory CashbookModel.fromJson(Map<String, dynamic> json) {
    final dt = parseCustomDate(json['ngay_gd'] ?? json['ngayGD'] ?? json['thoiGian']);
    final rawLoaiQuy = (json['loai_quy'] ?? json['loaiQuy'] ?? 'TIEN_MAT').toString().toUpperCase();
    final rawLoaiPhieu = (json['loai_phieu'] ?? json['loaiPhieu'] ?? 'THU').toString().toUpperCase();

    return CashbookModel(
      maPhieu: json['ma_phieu']?.toString() ?? json['maPhieu']?.toString() ?? '',
      chiNhanh: json['chi_nhanh']?.toString() ?? json['chiNhanh']?.toString() ?? 'CN02: Chi nhánh Thanh Giang',
      loaiPhieu: rawLoaiPhieu.contains('CHI') ? 'CHI' : 'THU',
      loaiQuy: (rawLoaiQuy.contains('TAI_KHOAN') || rawLoaiQuy.contains('NGAN_HANG')) ? 'TAI_KHOAN' : 'TIEN_MAT',
      ngayGD: dt,
      soTien: (json['so_tien'] as num?)?.toDouble() ?? (json['soTien'] as num?)?.toDouble() ?? 0.0,
      doiTuong: json['doi_tuong']?.toString() ?? json['doiTuong']?.toString() ?? json['nguoiNopNhan']?.toString() ?? '',
      maDoiTuong: json['ma_doi_tuong']?.toString() ?? json['maDoiTuong']?.toString() ?? '',
      maChungTu: json['ma_chung_tu']?.toString() ?? json['maChungTu']?.toString() ?? '',
      trangThai: json['trang_thai']?.toString() ?? json['trangThai']?.toString() ?? 'DaThanhToan',
      ghiChu: json['ghi_chu']?.toString() ?? json['ghiChu']?.toString() ?? json['lyDoThuChi']?.toString() ?? '',
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
