import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../branch/branch_view_model.dart';
import '../branch/branch_filter_chips.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_transfer_model.dart';
import '../../../data/models/stock_audit_model.dart';
import 'inventory_view_model.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryViewModel>().fetchInventory();
      context.read<InventoryViewModel>().fetchTransfers();
      context.read<InventoryViewModel>().fetchAudits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryViewModel>();
    final branchVm = context.watch<BranchViewModel>();

    final currentTotalStock = vm.products.fold(
      0.0,
      (sum, p) => sum + p.getTonKhoChoBoLoc(branchVm.selectedBranchCodes, branchVm.isAllSelected),
    );
    final currentTotalValue = vm.products.fold(
      0.0,
      (sum, p) => sum + (p.getTonKhoChoBoLoc(branchVm.selectedBranchCodes, branchVm.isAllSelected) * p.getGiaVonTaiChiNhanh(branchVm.selectedBranch.maCN)),
    );

    final filteredTransfers = vm.transfers.where((t) => t.isRelatedToBranch(branchVm.selectedBranch.maCN)).toList();
    final filteredAudits = vm.audits.where((a) => branchVm.matchesBranch(a.chiNhanh)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kho & Điều Chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            onPressed: () {
              vm.fetchInventory();
              vm.fetchTransfers();
              vm.fetchAudits();
            },
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
            Tab(text: 'Tồn kho (${vm.products.length})'),
            Tab(text: 'Chuyển kho (${filteredTransfers.length})'),
            Tab(text: 'Kiểm kho (${filteredAudits.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm hàng hóa'),
        onPressed: () => _showProductFormDialog(context, vm, branchVm),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 0: TỒN KHO & IMEI
          _buildInventoryTab(context, vm, branchVm, currentTotalStock, currentTotalValue),
          // TAB 1: CHUYỂN KHO
          _buildTransfersTab(context, vm, branchVm, filteredTransfers),
          // TAB 2: KIỂM KHO
          _buildAuditsTab(context, vm, branchVm, filteredAudits),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 0: TỒN KHO & IMEI
  // =========================================================================
  Widget _buildInventoryTab(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm,
    double currentTotalStock,
    double currentTotalValue,
  ) {
    return Column(
      children: [
        // Thống kê nhanh tổng tồn kho & giá trị
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng số lượng tồn', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${currentTotalStock.toInt()} cái/SP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.borderSubtle),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng giá trị vốn', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(currentTotalValue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.successGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã SP...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => vm.search(''),
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
            onChanged: vm.search,
          ),
        ),

        // Danh sách hàng hóa
        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          const Text('Không tìm thấy hàng hóa nào trong kho', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: vm.fetchInventory,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: vm.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = vm.products[index];
                          final tonKhoHienThi = product.getTonKhoChoBoLoc(
                            branchVm.selectedBranchCodes,
                            branchVm.isAllSelected,
                          );
                          final giaVonHienThi = product.getGiaVonTaiChiNhanh(branchVm.selectedBranch.maCN);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  product.maHang,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryBlue,
                                                    fontSize: 13,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (!product.coQuanLyImei)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.grey.shade300),
                                                    ),
                                                    child: const Text('Phụ kiện', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              product.tenHang,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMuted),
                                        padding: EdgeInsets.zero,
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showProductFormDialog(context, vm, branchVm, product: product);
                                          } else if (val == 'delete') {
                                            _confirmDeleteProduct(context, vm, product);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                                                SizedBox(width: 8),
                                                Text('Chỉnh sửa'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                                                SizedBox(width: 8),
                                                Text('Xóa hàng hóa', style: TextStyle(color: AppTheme.dangerRed)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Divider(height: 1, thickness: 0.8, color: AppTheme.borderSubtle.withOpacity(0.6)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Giá bán: ${Formatters.formatCurrency(product.giaBan)}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                      Text(
                                        'Giá vốn: ${Formatters.formatCurrency(giaVonHienThi)}',
                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tonKhoHienThi > 0 ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Tồn: ${tonKhoHienThi.toInt()} ${product.donViTinh}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: tonKhoHienThi > 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 1: CHUYỂN KHO (NHẬN HÀNG, SỬA, HỦY, LƯU TẠM)
  // =========================================================================
  Widget _buildTransfersTab(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm,
    List<StockTransferModel> transfers,
  ) {
    if (vm.isLoadingTransfers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 10),
            const Text('Không có phiếu chuyển kho nào cho chi nhánh này', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchTransfers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: transfers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final t = transfers[index];
          final isReceived = t.trangThai == 'Đã nhận';
          final isDraft = t.trangThai == 'Phiếu tạm';
          final isCancelled = t.trangThai == 'Đã hủy';
          final isShipping = t.trangThai == 'Đang chuyển';
          final canReceive = t.canReceive(branchVm.selectedBranch.maCN);

          Color statusBg = Colors.blue.withOpacity(0.12);
          Color statusFg = Colors.blue.shade700;
          if (isReceived) {
            statusBg = AppTheme.successGreen.withOpacity(0.12);
            statusFg = AppTheme.successGreen;
          } else if (isDraft) {
            statusBg = Colors.grey.withOpacity(0.12);
            statusFg = Colors.grey.shade700;
          } else if (isCancelled) {
            statusBg = AppTheme.dangerRed.withOpacity(0.12);
            statusFg = AppTheme.dangerRed;
          } else if (isShipping) {
            statusBg = Colors.amber.withOpacity(0.15);
            statusFg = Colors.orange.shade800;
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: canReceive ? AppTheme.successGreen.withOpacity(0.5) : AppTheme.borderSubtle,
                width: canReceive ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showTransferDetail(context, t),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng 1: Mã phiếu • Trạng thái • Nút hủy
                    Row(
                      children: [
                        Text(
                          t.maPhieu,
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
                            t.trangThai,
                            style: TextStyle(color: statusFg, fontWeight: FontWeight.bold, fontSize: 10.5),
                          ),
                        ),
                        const Spacer(),
                        if (t.canCancel)
                          InkWell(
                            onTap: () => _confirmCancelTransfer(context, vm, t),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.cancel_outlined, size: 18, color: AppTheme.dangerRed.withOpacity(0.7)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dòng 2: Chi nhánh chuyển -> Chi nhánh nhận
                    Row(
                      children: [
                        const Icon(Icons.outbox_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t.tuChiNhanh,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryBlue),
                        ),
                        const Icon(Icons.move_to_inbox_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            t.toiChiNhanh,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dòng 3: Thời gian • Số lượng • Giá trị
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatDateTime(t.ngayChuyen),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Text(
                          'SL: ${t.tongSoLuong} SP  •  ${Formatters.formatCurrency(t.tongTien)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                      ],
                    ),

                    // Nút NHẬN HÀNG nổi bật (nếu là chi nhánh nhận và chưa nhận)
                    if (canReceive) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('XÁC NHẬN NHẬN HÀNG VÀO KHO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _confirmReceiveTransfer(context, vm, branchVm, t),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB 2: KIỂM KHO (CÂN BẰNG KHO, SỬA, HỦY, LƯU TẠM)
  // =========================================================================
  Widget _buildAuditsTab(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm,
    List<StockAuditModel> audits,
  ) {
    if (vm.isLoadingAudits) {
      return const Center(child: CircularProgressIndicator());
    }

    if (audits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 10),
            const Text('Không có phiếu kiểm kho nào cho chi nhánh này', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchAudits,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: audits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = audits[index];
          final isBalanced = a.trangThai == 'Đã cân bằng kho';
          final isDraft = a.trangThai == 'Phiếu tạm';
          final isCancelled = a.trangThai == 'Đã hủy';

          Color statusBg = AppTheme.successGreen.withOpacity(0.12);
          Color statusFg = AppTheme.successGreen;
          if (isDraft) {
            statusBg = Colors.amber.withOpacity(0.15);
            statusFg = Colors.orange.shade800;
          } else if (isCancelled) {
            statusBg = AppTheme.dangerRed.withOpacity(0.12);
            statusFg = AppTheme.dangerRed;
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showAuditDetail(context, a),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng 1: Mã kiểm kho • Trạng thái • Nút hủy
                    Row(
                      children: [
                        Text(
                          a.maKiemKho,
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
                            a.trangThai,
                            style: TextStyle(color: statusFg, fontWeight: FontWeight.bold, fontSize: 10.5),
                          ),
                        ),
                        const Spacer(),
                        if (a.canCancel)
                          InkWell(
                            onTap: () => _confirmCancelAudit(context, vm, a),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.cancel_outlined, size: 18, color: AppTheme.dangerRed.withOpacity(0.7)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dòng 2: Chi nhánh & Thời gian
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            a.chiNhanh,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.formatDateTime(a.thoiGian),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dòng 3: Thực tế • Lệch • Giá trị lệch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thực tế: ${a.tongSoLuongThucTe} SP',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: a.tongSoLuongLech == 0
                                ? AppTheme.successGreen.withOpacity(0.1)
                                : (a.tongSoLuongLech > 0 ? Colors.blue.withOpacity(0.1) : AppTheme.dangerRed.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lệch: ${a.tongSoLuongLech > 0 ? "+" : ""}${a.tongSoLuongLech} SP',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: a.tongSoLuongLech == 0
                                  ? AppTheme.successGreen
                                  : (a.tongSoLuongLech > 0 ? AppTheme.primaryBlue : AppTheme.dangerRed),
                            ),
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(a.tongGiaTriChenhLech),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: a.tongGiaTriChenhLech >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),

                    // Nút CÂN BẰNG KHO (nếu là phiếu tạm)
                    if (a.canBalance) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.balance_rounded, size: 18),
                          label: const Text('CÂN BẰNG KHO THEO SỐ THỰC TẾ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _confirmBalanceAudit(context, vm, a),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // MODALS & DIALOGS CHO CHUYỂN KHO & KIỂM KHO
  // =========================================================================
  void _confirmReceiveTransfer(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm,
    StockTransferModel transfer,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nhận hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn xác nhận nhận hàng cho phiếu ${transfer.maPhieu}?\n\n'
          'Toàn bộ ${transfer.tongSoLuong} sản phẩm và danh sách IMEI sẽ tự động được nhập vào kho ${branchVm.selectedBranch.displayName}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bỏ qua')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.receiveTransfer(transfer.maPhieu, branchVm.selectedBranch.displayName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '✅ Đã nhận hàng thành công phiếu ${transfer.maPhieu}!' : '❌ Có lỗi khi nhận hàng!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('XÁC NHẬN NHẬN'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelTransfer(BuildContext context, InventoryViewModel vm, StockTransferModel transfer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy phiếu chuyển kho'),
        content: Text('Bạn có chắc chắn muốn hủy phiếu chuyển kho ${transfer.maPhieu}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.cancelTransfer(transfer.maPhieu);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã hủy phiếu chuyển kho ${transfer.maPhieu}' : 'Lỗi khi hủy phiếu!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('HỦY PHIẾU'),
          ),
        ],
      ),
    );
  }

  void _confirmBalanceAudit(BuildContext context, InventoryViewModel vm, StockAuditModel audit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận cân bằng kho'),
        content: Text(
          'Hệ thống sẽ cập nhật số lượng tồn kho theo số thực tế kiểm kê của phiếu ${audit.maKiemKho}.\n\n'
          'Tổng chênh lệch: ${audit.tongSoLuongLech} sản phẩm (${Formatters.formatCurrency(audit.tongGiaTriChenhLech)}).\n\n'
          'Bạn có muốn thực hiện ngay?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bỏ qua')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.balanceAudit(audit.maKiemKho);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '✅ Đã cân bằng kho thành công cho phiếu ${audit.maKiemKho}!' : '❌ Có lỗi khi cân bằng!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('CÂN BẰNG NGAY'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelAudit(BuildContext context, InventoryViewModel vm, StockAuditModel audit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy phiếu kiểm kho'),
        content: Text('Bạn có chắc chắn muốn hủy phiếu kiểm kho ${audit.maKiemKho}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.cancelAudit(audit.maKiemKho);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã hủy phiếu kiểm kho ${audit.maKiemKho}' : 'Lỗi khi hủy phiếu!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('HỦY PHIẾU'),
          ),
        ],
      ),
    );
  }

  void _showTransferDetail(BuildContext context, StockTransferModel transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chi tiết phiếu ${transfer.maPhieu}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text('Từ: ${transfer.tuChiNhanh} ➔ Đến: ${transfer.toiChiNhanh}', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
            Text('Trạng thái: ${transfer.trangThai}  •  Người lập: ${transfer.nguoiTao}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Divider(height: 16),
            const Text('Danh sách hàng hóa điều chuyển:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: transfer.chiTiet.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (c, i) {
                  final it = transfer.chiTiet[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(it.tenHang, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${it.maHang}  •  Số lượng: ${it.soLuong}  •  Đơn giá: ${Formatters.formatCurrency(it.donGia)}', style: const TextStyle(fontSize: 11.5)),
                        if (it.imeiList.isNotEmpty)
                          Text('IMEI: ${it.imeiList.join(", ")}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                      ],
                    ),
                    trailing: Text(Formatters.formatCurrency(it.thanhTien), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditDetail(BuildContext context, StockAuditModel audit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chi tiết kiểm kho ${audit.maKiemKho}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text('Chi nhánh: ${audit.chiNhanh}  •  Trạng thái: ${audit.trangThai}', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
            Text('Thời gian: ${Formatters.formatDateTime(audit.thoiGian)}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Divider(height: 16),
            const Text('Chi tiết sản phẩm kiểm đếm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: audit.chiTiet.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (c, i) {
                  final it = audit.chiTiet[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(it.tenHang, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Sổ sách: ${it.tonSoSach}  •  Thực tế: ${it.tonThucTe}', style: const TextStyle(fontSize: 11.5)),
                    trailing: Text(
                      'Lệch: ${it.slChenhLech > 0 ? "+" : ""}${it.slChenhLech}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: it.slChenhLech == 0 ? AppTheme.successGreen : (it.slChenhLech > 0 ? AppTheme.primaryBlue : AppTheme.dangerRed),
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
  }

  // =========================================================================
  // PRODUCT CRUD DIALOG (TỒN KHO)
  // =========================================================================
  void _confirmDeleteProduct(BuildContext context, InventoryViewModel vm, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hàng hóa'),
        content: Text('Bạn có chắc chắn muốn xóa hàng hóa "${product.tenHang}" (${product.maHang}) khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.deleteProduct(product.maHang);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã xóa hàng hóa ${product.tenHang}' : 'Lỗi khi xóa hàng hóa!'),
                    backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm, {
    ProductModel? product,
  }) {
    final isEdit = product != null;
    final codeCtrl = TextEditingController(text: product?.maHang ?? 'SP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController(text: product?.tenHang ?? '');
    final groupCtrl = TextEditingController(text: product?.tenNhom ?? 'Điện thoại & Phụ kiện');
    final unitCtrl = TextEditingController(text: product?.donViTinh ?? 'Cái');
    final costCtrl = TextEditingController(text: isEdit ? Formatters.formatCurrency(product.giaVon).replaceAll(' ₫', '') : '0');
    final priceCtrl = TextEditingController(text: isEdit ? Formatters.formatCurrency(product.giaBan).replaceAll(' ₫', '') : '0');
    final stockCtrl = TextEditingController(text: isEdit ? product.tonKho.toInt().toString() : '1');
    final branchCtrl = TextEditingController(text: product?.chiNhanh ?? branchVm.selectedBranch.displayName);

    bool imeiManaged = product?.coQuanLyImei ?? true;
    String status = product?.trangThai ?? 'DangKinhDoanh';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEdit ? 'Chỉnh sửa hàng hóa' : 'Thêm hàng hóa mới', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên hàng hóa (*)', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            enabled: !isEdit,
                            decoration: const InputDecoration(labelText: 'Mã hàng (*)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(labelText: 'Đơn vị tính', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá vốn (VNĐ)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá bán (VNĐ)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng tồn ban đầu', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Quản lý theo Serial / IMEI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: const Text('Bật nếu là điện thoại, máy tính bảng; Tắt nếu là phụ kiện, ốp lưng, sạc...', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                      value: imeiManaged,
                      onChanged: (val) => setModalState(() => imeiManaged = val ?? true),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                        icon: const Icon(Icons.check),
                        label: Text(isEdit ? 'LƯU THAY ĐỔI' : 'LƯU HÀNG HÓA', style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final code = codeCtrl.text.trim();
                          if (name.isEmpty || code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin (*)')));
                            return;
                          }

                          final cost = Formatters.parseCurrency(costCtrl.text);
                          final price = Formatters.parseCurrency(priceCtrl.text);
                          final stock = double.tryParse(stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

                          final newProductModel = ProductModel(
                            id: isEdit ? product.id : null,
                            maHang: code,
                            tenHang: name,
                            maNhom: isEdit ? product.maNhom : groupCtrl.text.trim(),
                            tenNhom: groupCtrl.text.trim(),
                            donViTinh: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'Cái',
                            giaVon: cost,
                            giaBan: price,
                            tonKho: stock,
                            chiNhanh: branchCtrl.text.trim().isNotEmpty ? branchCtrl.text.trim() : branchVm.selectedBranch.displayName,
                            coQuanLyImei: imeiManaged,
                            trangThai: status,
                          );

                          Navigator.pop(ctx);
                          final success = isEdit ? await vm.editProduct(newProductModel) : await vm.addProduct(newProductModel);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? (isEdit ? 'Đã cập nhật hàng hóa' : 'Đã thêm mới hàng hóa') : 'Có lỗi xảy ra!'),
                                backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
                              ),
                            );
                          }
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
