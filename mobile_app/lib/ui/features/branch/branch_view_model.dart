import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../core/app_theme.dart';

class BranchViewModel extends ChangeNotifier {
  static const String _prefKey = 'tt_pos_selected_chinhanh_codes';

  List<BranchModel> _branches = List.from(BranchModel.defaultBranches);
  Set<String> _selectedBranchCodes = {'CN01'};
  bool _isLoading = false;

  List<BranchModel> get branches => _branches;
  Set<String> get selectedBranchCodes => _selectedBranchCodes;
  bool get isLoading => _isLoading;

  bool get isAllSelected =>
      _selectedBranchCodes.contains('ALL') ||
      _selectedBranchCodes.isEmpty ||
      _selectedBranchCodes.length >= (_branches.length - 1);

  bool isBranchSelected(String code) {
    if (code.toUpperCase() == 'ALL') return isAllSelected;
    if (isAllSelected) return true;
    return _selectedBranchCodes.contains(code.toUpperCase());
  }

  BranchModel get selectedBranch {
    if (isAllSelected) {
      return _branches.firstWhere(
        (b) => b.maCN == 'ALL',
        orElse: () => BranchModel(maCN: 'ALL', tenCN: 'Toàn hệ thống (Tất cả chi nhánh)'),
      );
    }
    final firstCode = _selectedBranchCodes.first;
    return _branches.firstWhere(
      (b) => b.maCN.toUpperCase() == firstCode.toUpperCase(),
      orElse: () => _branches.firstWhere((b) => b.maCN != 'ALL', orElse: () => BranchModel.defaultBranches[1]),
    );
  }

  String get summaryDisplayName {
    if (isAllSelected) {
      return 'Toàn hệ thống (Tất cả chi nhánh)';
    }
    if (_selectedBranchCodes.length == 1) {
      return selectedBranch.displayName;
    }
    return '${_selectedBranchCodes.join(', ')} (${_selectedBranchCodes.length} chi nhánh)';
  }

  /// Kiểm tra xem một chuỗi chi nhánh (ví dụ "CN01: Trụ sở chính") có khớp với bộ lọc chi nhánh không
  bool matchesBranch(String? branchStr) {
    if (isAllSelected) return true;
    if (branchStr == null || branchStr.isEmpty) return true;

    final upper = branchStr.toUpperCase();
    for (final code in _selectedBranchCodes) {
      if (code == 'ALL') return true;
      if (upper.contains(code)) return true;
    }
    return false;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_prefKey);

      // 1. Tải danh mục chi nhánh từ Supabase nếu có
      try {
        final response = await SupabaseService.client
            .from('dm_chinhanh')
            .select('*')
            .order('ma_cn', ascending: true);

        if (response is List && response.isNotEmpty) {
          final loaded = response
              .map((item) => BranchModel.fromJson(item as Map<String, dynamic>))
              .where((b) => b.maCN.isNotEmpty && b.maCN != 'ALL')
              .toList();

          if (loaded.isNotEmpty) {
            _branches = [
              BranchModel(maCN: 'ALL', tenCN: 'Toàn hệ thống (Tất cả chi nhánh)'),
              ...loaded,
            ];
          }
        }
      } catch (e) {
        debugPrint("Không thể tải dm_chinhanh từ Supabase, dùng danh sách mặc định: $e");
      }

      // 2. Khôi phục danh sách chi nhánh đã chọn
      if (savedList != null && savedList.isNotEmpty) {
        _selectedBranchCodes = savedList.map((e) => e.toUpperCase()).toSet();
      } else {
        // Mặc định chọn CN01
        _selectedBranchCodes = {'CN01'};
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo BranchViewModel: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chọn 1 chi nhánh duy nhất (hoặc chọn Toàn hệ thống)
  Future<void> selectSingleBranch(String code) async {
    final upper = code.toUpperCase();
    _selectedBranchCodes = {upper};
    notifyListeners();
    _saveToPrefs();
  }

  /// Bật / tắt 1 chi nhánh (chọn nhiều chi nhánh)
  Future<void> toggleBranch(String code) async {
    final upper = code.toUpperCase();
    if (upper == 'ALL') {
      _selectedBranchCodes = {'ALL'};
    } else {
      _selectedBranchCodes.remove('ALL');
      if (_selectedBranchCodes.contains(upper)) {
        if (_selectedBranchCodes.length > 1) {
          _selectedBranchCodes.remove(upper);
        }
      } else {
        _selectedBranchCodes.add(upper);
      }
      if (_selectedBranchCodes.isEmpty) {
        _selectedBranchCodes = {'ALL'};
      }
    }
    notifyListeners();
    _saveToPrefs();
  }

  /// Chọn tất cả chi nhánh
  Future<void> selectAllBranches() async {
    _selectedBranchCodes = {'ALL'};
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _selectedBranchCodes.toList());
    } catch (e) {
      debugPrint("Lỗi lưu chi nhánh: $e");
    }
  }

  /// Hiển thị Modal BottomSheet chọn 1 hoặc nhiều chi nhánh trực quan
  static void showBranchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<BranchViewModel>(
          builder: (context, branchVm, _) {
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tùy chọn 1 hoặc nhiều chi nhánh để xem tổng quan, tồn kho & giao dịch:',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const Divider(height: 20),

                    // Danh sách chi nhánh kèm chọn linh hoạt
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 380),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: branchVm.branches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final b = branchVm.branches[index];
                          final isAll = b.maCN == 'ALL';
                          final isSelected = isAll
                              ? branchVm.isAllSelected
                              : (!branchVm.isAllSelected && branchVm.selectedBranchCodes.contains(b.maCN));

                          return InkWell(
                            onTap: () {
                              if (isAll) {
                                branchVm.selectAllBranches();
                              } else {
                                branchVm.toggleBranch(b.maCN);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withOpacity(0.08)
                                    : Colors.grey.shade50,
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
                                        fontSize: 11,
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
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppTheme.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (_) {
                                      if (isAll) {
                                        branchVm.selectAllBranches();
                                      } else {
                                        branchVm.toggleBranch(b.maCN);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nút xác nhận áp dụng
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          'ÁP DỤNG (${branchVm.summaryDisplayName})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🏢 Đang áp dụng: ${branchVm.summaryDisplayName}'),
                              backgroundColor: AppTheme.successGreen,
                              duration: const Duration(seconds: 2),
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
      },
    );
  }
}
