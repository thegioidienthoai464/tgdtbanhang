class BankModel {
  final String maNH;
  final String tenNH;
  final String soTK;
  final String chuTK;
  final String ghiChu;

  BankModel({
    required this.maNH,
    required this.tenNH,
    required this.soTK,
    this.chuTK = '',
    this.ghiChu = '',
  });

  String get displayName => '$tenNH - $soTK${chuTK.isNotEmpty ? " ($chuTK)" : ""}';

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      maNH: json['ma_nh']?.toString() ?? '',
      tenNH: json['ten_nh']?.toString() ?? '',
      soTK: json['so_tk']?.toString() ?? '',
      chuTK: json['chu_tk']?.toString() ?? '',
      ghiChu: json['ghi_chu']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nh': maNH,
      'ten_nh': tenNH,
      'so_tk': soTK,
      'chu_tk': chuTK,
      'ghi_chu': ghiChu,
    };
  }
}
