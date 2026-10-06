import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../core/app_theme.dart';

class BranchViewModel extends ChangeNotifier {
  static const String _prefKey = 'tt_pos_current_chinhanh';

  List<BranchModel> _branches = List.from(BranchModel.defaultBranches);
  BranchModel _selectedBranch = BranchModel.defaultBranches[0];
  bool _isLoading = false;

  List<BranchModel> get branches => _branches;
  BranchModel get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey) ?? 'CN01';

      // 1. Tải danh mục chi nhánh từ Supabase nếu có
      try {
        final response = await SupabaseService.client
            .from('dm_chinhanh')
            .select('*')
            .order('ma_cn', ascending: true);

        if (response is List && response.isNotEmpty) {
          final loaded = response
              .map((item) => BranchModel.fromJson(item as Map<String, dynamic>))
              .where((b) => b.maCN.isNotEmpty)
              .toList();

          if (loaded.isNotEmpty) {
            _branches = loaded;
          }
        }
      } catch (e) {
        debugPrint("Không thể tải dm_chinhanh từ Supabase, dùng danh sách mặc định: $e");
      }

      // 2. Tìm chi nhánh theo mã đã lưu
      final match = _branches.firstWhere(
        (b) => b.maCN.toUpperCase() == savedCode.toUpperCase() ||
               b.displayName.toUpperCase() == savedCode.toUpperCase(),
        orElse: () => _branches.isNotEmpty ? _branches[0] : BranchModel.defaultBranches[0],
      );

      _selectedBranch = match;
    } catch (e) {
      debugPrint("Lỗi khởi tạo BranchViewModel: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectBranch(BranchModel branch) async {
    if (_selectedBranch == branch) return;
    _selectedBranch = branch;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, branch.maCN);
    } catch (e) {
      debugPrint("Lỗi lưu chi nhánh: $e");
    }
  }

  /// Hiển thị Modal BottomSheet chọn chi nhánh trực quan
  static void showBranchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final branchVm = ctx.watch<BranchViewModel>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: AppTheme.primaryBlue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Chọn chi nhánh làm việc',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn chi nhánh để áp dụng vào hoạt động bán hàng POS, quản lý đơn hàng và ghi sổ quỹ.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const Divider(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: branchVm.branches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final b = branchVm.branches[index];
                      final isSelected = b.maCN == branchVm.selectedBranch.maCN;

                      return InkWell(
                        onTap: () {
                          branchVm.selectBranch(b);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🏢 Đã chuyển làm việc tại: ${b.displayName}'),
                              backgroundColor: AppTheme.successGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  b.maCN,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  b.tenCN,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 22)
                              else
                                const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
