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
      context.read<PosViewModel>().initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchVm = context.watch<BranchViewModel>();
    final ordersVm = context.watch<OrdersViewModel>();
    final invVm = context.watch<InventoryViewModel>();
    final cashVm = context.watch<CashbookViewModel>();
    final posVm = context.watch<PosViewModel>();

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
              posVm.initData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ordersVm.fetchOrders();
          await invVm.fetchInventory();
          await cashVm.fetchTransactions();
          await posVm.initData();
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
                      icon: Icons.bar_chart_rounded,
                      label: 'Truy cập báo cáo',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showReportsBottomSheet(context, branchVm, ordersVm, invVm, cashVm, posVm),
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

  // Modal Trung tâm báo cáo chuẩn như trên bản PC (Index.html - Mục 6. Báo cáo)
  void _showReportsBottomSheet(
    BuildContext context,
    BranchViewModel branchVm,
    OrdersViewModel ordersVm,
    InventoryViewModel invVm,
    CashbookViewModel cashVm,
    PosViewModel posVm,
  ) {
    // 6.1 Dữ liệu bán hàng
    final filteredSalesOrders = ordersVm.salesOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();
    final totalSales = filteredSalesOrders.fold(0.0, (sum, o) => sum + o.tongTien);
    final totalOrdersCount = filteredSalesOrders.length;
    final avgOrderValue = totalOrdersCount > 0 ? (totalSales / totalOrdersCount) : 0.0;

    // 6.2 Dữ liệu tồn kho
    final filteredProducts = branchVm.isAllSelected
        ? invVm.products
        : invVm.products.where((p) => branchVm.matchesBranch(p.chiNhanh)).toList();
    final totalStockQty = filteredProducts.fold(0.0, (sum, p) => sum + p.tonKho);
    final totalStockCost = filteredProducts.fold(0.0, (sum, p) => sum + (p.tonKho * p.giaVon));
    final lowStockCount = filteredProducts.where((p) => p.tonKho > 0 && p.tonKho <= 2).length;
    final outOfStockCount = filteredProducts.where((p) => p.tonKho == 0).length;

    // 6.3 Dữ liệu khách hàng & công nợ
    final customers = posVm.customers;
    final totalCustomerDebt = customers.fold(0.0, (sum, c) => sum + c.congNo);
    final debtCustomerCount = customers.where((c) => c.congNo > 0).length;

    // 6.4 Dữ liệu nhà cung cấp & nhập hàng
    final preOrdersCount = ordersVm.preOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).length;

    // 6.5 Dữ liệu tài chính & dòng tiền
    final totalCash = branchVm.isAllSelected ? cashVm.cashBalance : cashVm.filteredCashBalance(branchVm.matchesBranch);
    final totalBank = branchVm.isAllSelected ? cashVm.bankBalance : cashVm.filteredBankBalance(branchVm.matchesBranch);
    final totalFund = branchVm.isAllSelected ? cashVm.totalFund : cashVm.filteredTotalFund(branchVm.matchesBranch);
    final totalIncome = cashVm.transactions.where((t) => t.isIncome && branchVm.matchesBranch(t.chiNhanh)).fold(0.0, (sum, t) => sum + t.soTien);
    final totalExpense = cashVm.transactions.where((t) => t.isExpense && branchVm.matchesBranch(t.chiNhanh)).fold(0.0, (sum, t) => sum + t.soTien);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF8B5CF6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRUNG TÂM BÁO CÁO ERP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Áp dụng: ${branchVm.summaryDisplayName} • Đồng bộ chuẩn PC',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Danh sách 5 module báo cáo
              Expanded(
                child: ListView(
                  children: [
                    // 6.1 BÁO CÁO BÁN HÀNG
                    _buildReportCard(
                      ctx,
                      code: '6.1',
                      title: 'Báo cáo bán hàng',
                      subtitle: 'Doanh số, số lượng đơn & giá trị trung bình',
                      icon: Icons.point_of_sale,
                      color: AppTheme.primaryBlue,
                      items: [
                        _buildReportMetric('Tổng doanh thu bán', Formatters.formatCurrency(totalSales), isBold: true, valueColor: AppTheme.primaryBlue),
                        _buildReportMetric('Số lượng đơn bán', '$totalOrdersCount đơn'),
                        _buildReportMetric('Giá trị TB / đơn', Formatters.formatCurrency(avgOrderValue)),
                      ],
                      actionLabel: 'Xem danh sách đơn hàng',
                      onAction: () {
                        Navigator.pop(ctx);
                        widget.onTabChange(2); // Chuyển Tab Đơn hàng
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6.2 BÁO CÁO HÀNG HÓA & TỒN KHO
                    _buildReportCard(
                      ctx,
                      code: '6.2',
                      title: 'Báo cáo hàng hóa & tồn kho',
                      subtitle: 'Kiểm soát tồn kho, giá trị vốn & cảnh báo hết hàng',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.successGreen,
                      items: [
                        _buildReportMetric('Tổng tồn kho máy', '${totalStockQty.toInt()} cái', isBold: true, valueColor: AppTheme.successGreen),
                        _buildReportMetric('Tổng giá trị vốn kho', Formatters.formatCurrency(totalStockCost)),
                        _buildReportMetric('Cảnh báo hàng', '$outOfStockCount hết • $lowStockCount sắp hết', valueColor: outOfStockCount > 0 ? AppTheme.dangerRed : Colors.black87),
                      ],
                      actionLabel: 'Quản lý kho hàng',
                      onAction: () {
                        Navigator.pop(ctx);
                        widget.onTabChange(3); // Chuyển Tab Kho
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6.3 BÁO CÁO KHÁCH HÀNG & CÔNG NỢ
                    _buildReportCard(
                      ctx,
                      code: '6.3',
                      title: 'Báo cáo khách hàng & công nợ',
                      subtitle: 'Theo dõi tổng dư nợ khách hàng cần thu hồi',
                      icon: Icons.people_alt_outlined,
                      color: AppTheme.warningOrange,
                      items: [
                        _buildReportMetric('Tổng công nợ phải thu', Formatters.formatCurrency(totalCustomerDebt), isBold: true, valueColor: totalCustomerDebt > 0 ? AppTheme.dangerRed : AppTheme.successGreen),
                        _buildReportMetric('Số khách hàng còn nợ', '$debtCustomerCount / ${customers.length} khách'),
                      ],
                      actionLabel: 'Bán hàng & Thu nợ',
                      onAction: () {
                        Navigator.pop(ctx);
                        widget.onTabChange(1); // Chuyển Tab POS
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6.4 BÁO CÁO NHÀ CUNG CẤP & NHẬP HÀNG
                    _buildReportCard(
                      ctx,
                      code: '6.4',
                      title: 'Báo cáo nhà cung cấp & nhập hàng',
                      subtitle: 'Đơn vị phân phối thiết bị, đặt hàng chờ nhập',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.teal,
                      items: [
                        _buildReportMetric('Đơn đặt hàng chờ nhập', '$preOrdersCount đơn hàng'),
                        _buildReportMetric('Đối tác liên kết', 'Đồng bộ từ hệ thống web ERP'),
                      ],
                      actionLabel: 'Xem đơn đặt hàng',
                      onAction: () {
                        Navigator.pop(ctx);
                        widget.onTabChange(2);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6.5 BÁO CÁO TÀI CHÍNH & DÒNG TIỀN
                    _buildReportCard(
                      ctx,
                      code: '6.5',
                      title: 'Báo cáo tài chính & dòng tiền',
                      subtitle: 'Tổng thu, tổng chi, quỹ tiền mặt và ngân hàng',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF8B5CF6),
                      items: [
                        _buildReportMetric('Tổng tồn quỹ ròng', Formatters.formatCurrency(totalFund), isBold: true, valueColor: totalFund >= 0 ? AppTheme.successGreen : AppTheme.dangerRed),
                        _buildReportMetric('Quỹ tiền mặt', Formatters.formatCurrency(totalCash)),
                        _buildReportMetric('Quỹ ngân hàng', Formatters.formatCurrency(totalBank)),
                        _buildReportMetric('Tổng dòng tiền thu', '+${Formatters.formatCurrency(totalIncome)}', valueColor: AppTheme.successGreen),
                        _buildReportMetric('Tổng dòng tiền chi', '-${Formatters.formatCurrency(totalExpense)}', valueColor: AppTheme.dangerRed),
                      ],
                      actionLabel: 'Mở sổ quỹ chi tiết',
                      onAction: () {
                        Navigator.pop(ctx);
                        widget.onTabChange(4); // Chuyển Tab Sổ quỹ
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> items,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const Divider(height: 16),
            ...items,
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: color,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportMetric(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: isBold ? Colors.black87 : AppTheme.textMuted, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
