import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/order_model.dart';
import 'orders_view_model.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersViewModel>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrdersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.fetchOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryBlue,
          tabs: [
            Tab(text: 'Đặt hàng (${vm.preOrders.length})'),
            Tab(text: 'Bán hàng (${vm.salesOrders.length})'),
            Tab(text: 'Nhập kho (${vm.importOrders.length})'),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(context, vm.preOrders, isPreOrder: true),
                _buildOrderList(context, vm.salesOrders),
                _buildOrderList(context, vm.importOrders, isImport: true),
              ],
            ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<OrderModel> orders, {bool isPreOrder = false, bool isImport = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Chưa có đơn hàng nào', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrdersViewModel>().fetchOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final o = orders[index];
          final isCompleted = o.trangThai == 'Hoàn thành';
          final isCancelled = o.trangThai == 'Đã hủy';

          Color statusBg = AppTheme.warningOrange.withOpacity(0.12);
          Color statusFg = AppTheme.warningOrange;
          if (isCompleted) {
            statusBg = AppTheme.successGreen.withOpacity(0.12);
            statusFg = AppTheme.successGreen;
          } else if (isCancelled) {
            statusBg = AppTheme.dangerRed.withOpacity(0.12);
            statusFg = AppTheme.dangerRed;
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      o.maDonHang,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        o.trangThai,
                        style: TextStyle(
                          color: statusFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isImport ? Icons.local_shipping_outlined : Icons.person_outline, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        o.tenKH,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      Formatters.formatDateTime(o.ngayBan),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPreOrder ? 'Tiền cọc:' : (isImport ? 'Đã trả:' : 'Hình thức:'),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        Text(
                          isPreOrder || isImport
                              ? Formatters.formatCurrency(o.khachTra)
                              : (o.hinhThucTT == 'TIEN_MAT' ? 'Tiền mặt' : 'Chuyển khoản'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPreOrder ? AppTheme.successGreen : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tổng tiền:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          Formatters.formatCurrency(o.tongTien),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
