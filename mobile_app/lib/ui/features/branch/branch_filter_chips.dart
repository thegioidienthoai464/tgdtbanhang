import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import 'branch_view_model.dart';

class BranchFilterChips extends StatelessWidget {
  final bool showHeader;
  final String? title;

  const BranchFilterChips({
    super.key,
    this.showHeader = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final branchVm = context.watch<BranchViewModel>();
    final branches = branchVm.branches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      title ?? 'Chi nhánh áp dụng:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primaryBlue),
                  label: const Text(
                    'Tùy chọn chi tiết',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                  onPressed: () => BranchViewModel.showBranchBottomSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 1. Chip "Toàn hệ thống (Tất cả)"
              _buildChip(
                context: context,
                label: 'Toàn hệ thống',
                code: 'ALL',
                isSelected: branchVm.isAllSelected,
                isAll: true,
                onTap: () => branchVm.selectAllBranches(),
              ),
              const SizedBox(width: 8),

              // 2. Các chip từng chi nhánh cụ thể
              ...branches.where((b) => b.maCN != 'ALL').map((b) {
                final isSelected = !branchVm.isAllSelected && branchVm.selectedBranchCodes.contains(b.maCN);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    context: context,
                    label: b.tenCN,
                    code: b.maCN,
                    isSelected: isSelected,
                    isAll: false,
                    onTap: () => branchVm.toggleBranch(b.maCN),
                    onLongPress: () {
                      branchVm.selectSingleBranch(b.maCN);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🏢 Đang xem riêng: ${b.tenCN}'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }),

              // 3. Nút mở popup chọn chi nhánh
              InkWell(
                onTap: () => BranchViewModel.showBranchBottomSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist_rtl_rounded, size: 16, color: AppTheme.primaryBlue),
                      SizedBox(width: 4),
                      Text(
                        'Chọn nhiều...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required String code,
    required bool isSelected,
    required bool isAll,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAll ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.12))
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : (isAll ? Icons.public : Icons.storefront),
                size: 15,
                color: isSelected
                    ? (isAll ? Colors.white : AppTheme.primaryBlue)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isAll ? Colors.white : AppTheme.primaryBlue)
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
