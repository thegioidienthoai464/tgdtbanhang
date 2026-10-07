class BranchModel {
  final String maCN;
  final String tenCN;

  BranchModel({
    required this.maCN,
    required this.tenCN,
  });

  String get displayName => '$maCN: $tenCN';

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      maCN: json['ma_cn']?.toString() ?? json['ma']?.toString() ?? '',
      tenCN: json['ten_cn']?.toString() ?? json['ten']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_cn': maCN,
      'ten_cn': tenCN,
    };
  }

  bool get isAll => maCN.toUpperCase() == 'ALL';

  static final List<BranchModel> defaultBranches = [
    BranchModel(maCN: 'ALL', tenCN: 'Toàn hệ thống (Tất cả chi nhánh)'),
    BranchModel(maCN: 'CN01', tenCN: 'Trụ sở chính Thanh Miện'),
    BranchModel(maCN: 'CN02', tenCN: 'Chi nhánh Thanh Giang'),
    BranchModel(maCN: 'CN03', tenCN: 'Chi nhánh Bình Giang'),
    BranchModel(maCN: 'CN04', tenCN: 'Bán Online'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchModel &&
          runtimeType == other.runtimeType &&
          maCN.toUpperCase() == other.maCN.toUpperCase();

  @override
  int get hashCode => maCN.toUpperCase().hashCode;
}
