import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
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
    final ordersVm = context.watch<OrdersViewModel>();
    final invVm = context.watch<InventoryViewModel>();
    final cashVm = context.watch<CashbookViewModel>();

    final todaySales = ordersVm.salesOrders.fold(0.0, (sum, o) => sum + o.tongTien);
    final preOrdersCount = ordersVm.preOrders.where((o) => o.trangThai != 'Đã hủy').length;

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
              // Lời chào & Chi nhánh
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
                      width: 52,
                      height: 52,
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

              const Text('Chỉ số hoạt động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    icon: Icons.payments_outlined,
                    color: AppTheme.primaryBlue,
                    onTap: () => widget.onTabChange(2), // Tab Đơn hàng
                  ),
                  _buildKpiCard(
                    title: 'Đơn đặt hàng chờ',
                    value: '$preOrdersCount đơn',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.warningOrange,
                    onTap: () => widget.onTabChange(2), // Tab Đơn hàng
                  ),
                  _buildKpiCard(
                    title: 'Tồn kho máy',
                    value: '${invVm.totalStock.toInt()} sản phẩm',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.successGreen,
                    onTap: () => widget.onTabChange(3), // Tab Kho
                  ),
                  _buildKpiCard(
                    title: 'Tồn quỹ tiền',
                    value: Formatters.formatCurrency(cashVm.balance),
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => widget.onTabChange(3), // Tab Sổ quỹ
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
