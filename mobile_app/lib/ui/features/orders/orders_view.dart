import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/lan_printer_service.dart';
import '../branch/branch_view_model.dart';
import '../branch/branch_filter_chips.dart';
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
    final branchVm = context.watch<BranchViewModel>();

    final filteredPreOrders = vm.preOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();
    final filteredSalesOrders = vm.salesOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();
    final filteredImportOrders = vm.importOrders.where((o) => branchVm.matchesBranch(o.chiNhanh)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quản lý đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              branchVm.summaryDisplayName,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Chọn chi nhánh',
            onPressed: () => BranchViewModel.showBranchBottomSheet(context),
          ),
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
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: [
            Tab(text: 'Đặt hàng (${filteredPreOrders.length})'),
            Tab(text: 'Bán hàng (${filteredSalesOrders.length})'),
            Tab(text: 'Nhập kho (${filteredImportOrders.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thanh lọc chi nhánh ngang nhỏ gọn (Đã loại bỏ thanh Chi nhánh chiếm diện tích ở thân trang)
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 6, 10, 2),
            child: BranchFilterChips(),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(context, filteredPreOrders, isPreOrder: true),
                      _buildOrderList(context, filteredSalesOrders),
                      _buildOrderList(context, filteredImportOrders, isImport: true),
                    ],
                  ),
          ),
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
            Icon(Icons.inbox_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text(
              isPreOrder ? 'Chưa có đơn đặt hàng nào' : (isImport ? 'Chưa có đơn nhập kho nào' : 'Chưa có đơn bán hàng nào'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrdersViewModel>().fetchOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
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

          final branchShort = o.chiNhanh.contains(':') ? o.chiNhanh.split(':').first.trim() : o.chiNhanh;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showOrderDetailBottomSheet(context, o, isImport: isImport, isPreOrder: isPreOrder),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng 1: Mã đơn hàng • Badge trạng thái • Nút xóa
                    Row(
                      children: [
                        Text(
                          o.maDonHang,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            fontSize: 13.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            o.trangThai,
                            style: TextStyle(
                              color: statusFg,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _confirmDeleteOrder(context, o),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Dòng 2: Tên khách hàng / NCC • Chi nhánh • Thời gian
                    Row(
                      children: [
                        Icon(isImport ? Icons.local_shipping_outlined : Icons.person_outline, size: 13.5, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            o.tenKH.isNotEmpty ? o.tenKH : 'Khách lẻ',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (branchShort.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              branchShort,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          Formatters.formatDateTime(o.ngayBan),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Đường ngăn mỏng
                    Divider(height: 1, thickness: 0.8, color: AppTheme.borderSubtle.withOpacity(0.6)),
                    const SizedBox(height: 5),

                    // Dòng 3: Hình thức / Tiền cọc / Số SP & Tổng tiền
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (o.hinhThucTT == 'TIEN_MAT') ? Icons.payments_outlined : Icons.account_balance_outlined,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPreOrder
                                  ? 'Cọc: ${Formatters.formatCurrency(o.khachTra)}'
                                  : (isImport
                                      ? 'Đã trả: ${Formatters.formatCurrency(o.khachTra)}'
                                      : (o.hinhThucTT == 'TIEN_MAT' ? 'Tiền mặt' : 'Chuyển khoản')),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isPreOrder ? AppTheme.successGreen : AppTheme.textMuted,
                                fontWeight: isPreOrder ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            if (o.chiTietSanPham.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${o.chiTietSanPham.length} SP',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Tổng: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
                            Text(
                              Formatters.formatCurrency(o.tongTien),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Modal Chi tiết Đơn hàng & Hành động In / Xóa
  void _showOrderDetailBottomSheet(BuildContext context, OrderModel o, {bool isImport = false, bool isPreOrder = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          expand: false,
          builder: (_, scrollController) {
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

            return Column(
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Tiêu đề & Đóng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isPreOrder ? 'Đơn đặt hàng' : (isImport ? 'Đơn nhập kho' : 'Đơn bán hàng'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                            child: Text(o.trangThai, style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Nội dung chi tiết
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Thẻ thông tin chung
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Mã chứng từ:', o.maDonHang, isBold: true, isCopyable: true, context: context),
                            const SizedBox(height: 6),
                            _buildInfoRow(isImport ? 'Nhà cung cấp:' : 'Khách hàng:', o.tenKH.isNotEmpty ? o.tenKH : 'Khách lẻ'),
                            if (o.soDienThoai.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _buildInfoRow('Số điện thoại:', o.soDienThoai),
                            ],
                            const SizedBox(height: 6),
                            _buildInfoRow('Chi nhánh:', o.chiNhanh),
                            const SizedBox(height: 6),
                            _buildInfoRow('Thời gian:', Formatters.formatDateTime(o.ngayBan)),
                            if (o.nhanVien.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _buildInfoRow('Nhân viên:', o.nhanVien),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Danh sách hàng hóa
                      Text(
                        'Danh sách sản phẩm (${o.chiTietSanPham.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (o.chiTietSanPham.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Không có chi tiết mặt hàng', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        )
                      else
                        ...o.chiTietSanPham.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.tenHang,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(item.thanhTien),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.soLuong} x ${Formatters.formatCurrency(item.donGia)}',
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                    if (item.imeiStr.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'IMEI: ${item.imeiStr}',
                                          style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 12),

                      // Tóm tắt tài chính
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            _buildMoneyRow('Tổng giá trị hàng:', Formatters.formatCurrency(o.tongTien)),
                            if (o.giamGia > 0) ...[
                              const SizedBox(height: 4),
                              _buildMoneyRow('Chiết khấu / Giảm giá:', '-${Formatters.formatCurrency(o.giamGia)}', color: AppTheme.dangerRed),
                            ],
                            const SizedBox(height: 4),
                            _buildMoneyRow(
                              isPreOrder ? 'Tiền cọc đã nhận:' : (isImport ? 'Đã thanh toán NCC:' : 'Khách đã trả:'),
                              Formatters.formatCurrency(o.khachTra),
                              color: AppTheme.successGreen,
                            ),
                            if (o.khachPhaiTra > o.khachTra) ...[
                              const SizedBox(height: 4),
                              _buildMoneyRow(
                                isImport ? 'Còn nợ NCC:' : 'Còn nợ lại:',
                                Formatters.formatCurrency(o.khachPhaiTra - o.khachTra),
                                color: AppTheme.dangerRed,
                                isBold: true,
                              ),
                            ],
                            const Divider(height: 12),
                            _buildMoneyRow(
                              'Hình thức thanh toán:',
                              o.hinhThucTT == 'TIEN_MAT' ? 'Tiền mặt' : 'Chuyển khoản ${o.nganHangNhan ?? ""}'.trim(),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Thanh hành động dưới cùng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.dangerRed),
                              foregroundColor: AppTheme.dangerRed,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteOrder(context, o);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('In bill LAN', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final res = await LanPrinterService.printOrderReceipt(o);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Đã gửi lệnh in!'),
                                    backgroundColor: res['success'] == true ? AppTheme.successGreen : AppTheme.dangerRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, bool isCopyable = false, BuildContext? context}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: isBold ? AppTheme.primaryBlue : AppTheme.textDark,
                  ),
                ),
              ),
              if (isCopyable && context != null) ...[
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép $value'), duration: const Duration(seconds: 1)),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.copy_outlined, size: 14, color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoneyRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteOrder(BuildContext context, OrderModel o) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa đơn hàng [${o.maDonHang}] không? Thao tác này sẽ xóa đơn và phiếu thu liên quan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dCtx);
              final ok = await context.read<OrdersViewModel>().deleteOrder(o.maDonHang);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã xóa đơn hàng ${o.maDonHang} thành công!' : 'Lỗi xóa đơn hàng!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('Xóa đơn'),
          ),
        ],
      ),
    );
  }
}
