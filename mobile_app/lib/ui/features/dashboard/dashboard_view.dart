import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../branch/branch_view_model.dart';
import '../branch/branch_filter_chips.dart';
import '../pos/pos_view_model.dart';
import '../orders/orders_view_model.dart';
import '../inventory/inventory_view_model.dart';
import '../cashbook/cashbook_view_model.dart';
import '../settings/settings_view.dart';


class DashboardView extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardView({super.key, required this.onTabChange});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersViewModel>().fetchOrders();
      context.read<InventoryViewModel>().fetchInventory();
      context.read<CashbookViewModel>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchVm = context.watch<BranchViewModel>();
    final ordersVm = context.watch<OrdersViewModel>();
    final invVm = context.watch<InventoryViewModel>();
    final cashVm = context.watch<CashbookViewModel>();

    // Lọc theo 1 hoặc nhiều chi nhánh được chọn (hoặc Toàn hệ thống)
    final filteredSalesOrders = ordersVm.salesOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();
    final filteredPreOrders = ordersVm.preOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();

    final todaySales = filteredSalesOrders.fold(0.0, (sum, o) => sum + o.tongTien);
    final preOrdersCount = filteredPreOrders.where((o) => o.trangThai != 'Đã hủy').length;

    // Tồn kho lọc theo chi nhánh
    final currentStock = branchVm.isAllSelected
        ? invVm.totalStock
        : invVm.products.where((p) => branchVm.matchesBranch(p.chiNhanh)).fold(0.0, (sum, p) => sum + p.tonKho);

    // Quỹ tiền lọc theo chi nhánh
    final currentFund = branchVm.isAllSelected
        ? cashVm.totalFund
        : cashVm.filteredTotalFund(branchVm.matchesBranch);

    final branchBadge = branchVm.isAllSelected
        ? 'Toàn hệ thống'
        : (branchVm.selectedBranchCodes.length == 1
            ? 'CN: ${branchVm.selectedBranchCodes.first}'
            : '${branchVm.selectedBranchCodes.length} chi nhánh');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.point_of_sale, color: Colors.amber, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            const Text('T&T POS', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Nút chọn chi nhánh trên AppBar (Vị trí số 1 duy nhất)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: InkWell(
              onTap: () => BranchViewModel.showBranchBottomSheet(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      branchVm.isAllSelected
                          ? 'Tất cả CN'
                          : (branchVm.selectedBranchCodes.length == 1
                              ? branchVm.selectedBranchCodes.first
                              : '${branchVm.selectedBranchCodes.length} CN'),
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt hệ thống',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ordersVm.fetchOrders();
              invVm.fetchInventory();
              cashVm.fetchTransactions();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ordersVm.fetchOrders();
          await invVm.fetchInventory();
          await cashVm.fetchTransactions();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner thương hiệu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: Colors.amber, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('T&T POS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                          SizedBox(height: 2),
                          Text('Hệ thống Quản lý Bán hàng & Kho ERP', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= CHỈ SỐ HOẠT ĐỘNG =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉ số hoạt động',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.primaryBlue),
                          const SizedBox(width: 3),
                          Text(
                            'Áp dụng: $branchBadge',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 15, color: AppTheme.primaryBlue),
                    label: const Text(
                      'Tùy chọn CN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    onPressed: () => BranchViewModel.showBranchBottomSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // THANH CHỌN 1 HOẶC NHIỀU CHI NHÁNH TRỰC QUAN NGAY TẠI CHỈ SỐ HOẠT ĐỘNG
              const BranchFilterChips(),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '💡 Chạm chọn 1 hoặc nhiều chi nhánh, chạm giữ để xem riêng 1 chi nhánh',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),

              // Lưới các thẻ KPI
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildKpiCard(
                    title: 'Doanh số bán',
                    value: Formatters.formatCurrency(todaySales),
                    subtitle: branchBadge,
                    icon: Icons.payments_outlined,
                    color: AppTheme.primaryBlue,
                    onTap: () => widget.onTabChange(2), // Tab Đơn hàng
                  ),
                  _buildKpiCard(
                    title: 'Đơn đặt hàng chờ',
                    value: '$preOrdersCount đơn',
                    subtitle: branchBadge,
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.warningOrange,
                    onTap: () => widget.onTabChange(2), // Tab Đơn hàng
                  ),
                  _buildKpiCard(
                    title: 'Tồn kho máy',
                    value: '${currentStock.toInt()} sản phẩm',
                    subtitle: branchBadge,
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.successGreen,
                    onTap: () => widget.onTabChange(3), // Tab Kho
                  ),
                  _buildKpiCard(
                    title: 'Tổng tồn quỹ',
                    value: Formatters.formatCurrency(currentFund),
                    subtitle: branchBadge,
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => widget.onTabChange(4), // Tab Sổ quỹ (index 4)
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('Hành động nhanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.point_of_sale,
                      label: 'Bán hàng POS',
                      color: AppTheme.primaryBlue,
                      onTap: () => widget.onTabChange(1), // Chuyển sang Tab POS
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.qr_code_scanner,
                      label: 'Quét Barcode',
                      color: AppTheme.successGreen,
                      onTap: () => widget.onTabChange(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
