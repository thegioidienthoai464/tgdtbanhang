import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/models/order_model.dart';
import '../branch/branch_view_model.dart';
import '../settings/settings_view.dart';
import 'pos_view_model.dart';

class PosView extends StatefulWidget {
  const PosView({super.key});

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosViewModel>().initData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PosViewModel>();
    final branchVm = context.watch<BranchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu ngân POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Cài đặt máy in LAN',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
            tooltip: 'Quét Barcode / IMEI',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng quét Barcode camera đã sẵn sàng!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.initData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh hiển thị & chuyển đổi chi nhánh POS
          InkWell(
            onTap: () => BranchViewModel.showBranchBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.06),
                border: Border(bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'Chi nhánh: ', style: TextStyle(color: AppTheme.textMuted)),
                          TextSpan(
                            text: branchVm.selectedBranch.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Đổi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Mục Chọn Khách Hàng POS
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: vm.selectedCustomer != null 
                    ? AppTheme.primaryBlue.withOpacity(0.5) 
                    : AppTheme.borderSubtle,
                width: vm.selectedCustomer != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (vm.selectedCustomer != null && vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE')
                      ? AppTheme.primaryBlue.withOpacity(0.12) 
                      : Colors.grey.shade100,
                  child: Icon(
                    (vm.selectedCustomer != null && vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE')
                        ? Icons.person
                        : Icons.storefront,
                    size: 18,
                    color: (vm.selectedCustomer != null && vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE')
                        ? AppTheme.primaryBlue 
                        : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _showCustomerSelectorBottomSheet(context, vm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              (vm.selectedCustomer == null || vm.selectedCustomer!.maDoiTac.trim().toUpperCase() == 'KHACHLE')
                                  ? 'Khách lẻ (Mặc định)'
                                  : vm.selectedCustomer!.tenDoiTac,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: (vm.selectedCustomer == null || vm.selectedCustomer!.maDoiTac.trim().toUpperCase() == 'KHACHLE')
                                    ? Colors.black87
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                            if (vm.selectedCustomer != null && 
                                vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE' &&
                                vm.selectedCustomer!.soDienThoai.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${vm.selectedCustomer!.soDienThoai}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ],
                        ),
                        if (vm.selectedCustomer != null && vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE')
                          Text(
                            'Nợ hiện tại: ${Formatters.formatCurrency(vm.selectedCustomer!.congNo)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: vm.selectedCustomer!.congNo > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                            ),
                          )
                        else
                          const Text(
                            'Mã: KHACHLE • Chạm để đổi khách quen hoặc ghi nợ',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
                if (vm.selectedCustomer != null && vm.selectedCustomer!.maDoiTac.trim().toUpperCase() != 'KHACHLE')
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                    tooltip: 'Đổi về Khách lẻ',
                    onPressed: () => vm.setCustomer(null),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.person_search_outlined, size: 16),
                        label: const Text('Chọn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCustomerSelectorBottomSheet(context, vm),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                          foregroundColor: AppTheme.primaryBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.person_add_alt_1, size: 15),
                        label: const Text('+ Thêm KH', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showQuickAddCustomerDialog(context, vm),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 3. Thanh tìm kiếm sản phẩm & Quét mã vạch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên, mã sản phẩm...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppTheme.textMuted),
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchCtrl.clear();
                          vm.searchProducts('');
                          setState(() {});
                        },
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue, size: 22),
                        tooltip: 'Quét mã vạch / QR sản phẩm',
                        onPressed: () => _openBarcodeScanner(context, vm),
                      ),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
              ),
              onChanged: (val) {
                vm.searchProducts(val);
                setState(() {});
              },
            ),
          ),

          // 4. Danh sách sản phẩm
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.products.isEmpty
                    ? const Center(child: Text('Không tìm thấy sản phẩm nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: vm.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = vm.products[index];
                          final isInCart = vm.cart.any((item) => item.maHang == p.maHang);
                          final posStock = p.getTonKhoChoBoLoc(branchVm.selectedBranchCodes, branchVm.isAllSelected);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isInCart ? AppTheme.primaryBlue : AppTheme.borderSubtle,
                                width: isInCart ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.phone_android, color: AppTheme.primaryBlue),
                              ),
                              title: Text(
                                p.tenHang,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    Formatters.formatCurrency(p.giaBan),
                                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• Tồn: ${posStock.toInt()}',
                                    style: TextStyle(
                                      color: posStock > 0 ? AppTheme.textMuted : AppTheme.dangerRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryBlue),
                                onPressed: () {
                                  vm.addToCart(p);
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm ${p.tenHang} vào giỏ'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 5. Thanh tóm tắt giỏ hàng phía dưới
          if (vm.cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCartBottomSheet(context, vm, branchVm),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${vm.totalItemCount} sản phẩm • ${vm.selectedCustomer?.tenDoiTac ?? "Khách lẻ"}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_note, size: 16, color: AppTheme.primaryBlue),
                              ],
                            ),
                            Text(
                              Formatters.formatCurrency(vm.subtotal),
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        side: const BorderSide(color: AppTheme.primaryBlue),
                      ),
                      icon: const Icon(Icons.format_list_bulleted, size: 18, color: AppTheme.primaryBlue),
                      label: const Text('Xem giỏ', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12.5)),
                      onPressed: () => _showCartBottomSheet(context, vm, branchVm),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Thanh toán'),
                      onPressed: () => _showCheckoutModal(context, vm, branchVm),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // BottomSheet Chọn Khách Hàng
  void _showCustomerSelectorBottomSheet(BuildContext context, PosViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredList = vm.customers.where((c) {
              if (filter.isEmpty) return true;
              final q = filter.toLowerCase();
              return c.tenDoiTac.toLowerCase().contains(q) ||
                     c.soDienThoai.contains(q) ||
                     c.maDoiTac.toLowerCase().contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn Khách Hàng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Tạo mới'),
                        onPressed: () => _showQuickAddCustomerDialog(context, vm, setSheetState),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, SĐT khách hàng...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() {
                        filter = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dòng chọn Khách lẻ mặc định
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.storefront, color: AppTheme.primaryBlue),
                    ),
                    title: const Text('Khách lẻ (Mã: KHACHLE)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Mặc định • Bán lẻ thu tiền ngay', style: TextStyle(fontSize: 12)),
                    trailing: (vm.selectedCustomer == null || vm.selectedCustomer!.maDoiTac.trim().toUpperCase() == 'KHACHLE')
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue) 
                        : null,
                    onTap: () {
                      vm.setCustomer(null);
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('Không tìm thấy khách hàng phù hợp'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final c = filteredList[i];
                              final isSelected = vm.selectedCustomer?.maDoiTac == c.maDoiTac;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                  child: Text(
                                    c.tenDoiTac.isNotEmpty ? c.tenDoiTac[0].toUpperCase() : 'K',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                                title: Text(c.tenDoiTac, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${c.soDienThoai.isNotEmpty ? c.soDienThoai : "Chưa có SĐT"} • Nợ: ${Formatters.formatCurrency(c.congNo)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.congNo > 0 ? AppTheme.dangerRed : AppTheme.textMuted,
                                    fontWeight: c.congNo > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue)
                                    : null,
                                onTap: () {
                                  vm.setCustomer(c);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Dialog / Modal Tạo khách hàng mới đầy đủ thông tin
  void _showQuickAddCustomerDialog(BuildContext context, PosViewModel vm, [StateSetter? parentSetState]) {
    final now = DateTime.now();
    final defaultCode = "KH${now.millisecondsSinceEpoch.toString().substring(7)}";

    final codeCtrl = TextEditingController(text: defaultCode);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final debtCtrl = TextEditingController(text: '0');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(dCtx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thêm khách hàng mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('Điền đầy đủ thông tin để quản lý công nợ & lịch sử mua hàng', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(dCtx),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 1. Mã khách hàng & Tên khách hàng
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mã khách hàng',
                          hintText: 'VD: KH0123',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Tên khách hàng (*)',
                          hintText: 'VD: Nguyễn Văn A',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Số điện thoại
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'VD: 0988888888',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Địa chỉ
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    hintText: 'VD: Thanh Miện, Hải Dương',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Công nợ ban đầu
                TextField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Công nợ ban đầu (VNĐ)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Ghi chú
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Ghi chú thêm về khách hàng...',
                    prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('LƯU KHÁCH HÀNG', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập tên khách hàng (*)')),
                            );
                            return;
                          }

                          final code = codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : defaultCode;
                          final debt = Formatters.parseCurrency(debtCtrl.text);

                          Navigator.pop(dCtx);
                          final created = await vm.createFullCustomer(
                            maKH: code,
                            tenKH: name,
                            soDienThoai: phoneCtrl.text.trim(),
                            diaChi: addressCtrl.text.trim(),
                            congNo: debt,
                            ghiChu: noteCtrl.text.trim(),
                          );

                          if (created != null) {
                            if (parentSetState != null) {
                              parentSetState(() {});
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã tạo khách hàng thành công: ${created.tenDoiTac} (${created.maDoiTac})'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lỗi tạo khách hàng, vui lòng thử lại!'),
                                backgroundColor: AppTheme.dangerRed,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal Xác Nhận Thanh Toán Toàn Diện (Checkbox Tiền mặt, Ngân hàng, Thẻ POS & Kết hợp cả 3)
  void _showCheckoutModal(BuildContext context, PosViewModel vm, BranchViewModel branchVm) {
    final subtotal = vm.subtotal;
    
    // State cục bộ cho modal thanh toán dạng Checkbox
    bool isCash = true;
    bool isBank = false;
    bool isPosCard = false;
    bool isDebtOnly = (vm.paymentMethod == 'CON_NO');
    if (isDebtOnly) {
      isCash = false;
      isBank = false;
      isPosCard = false;
    } else if (vm.paymentMethod == 'TAI_KHOAN') {
      isCash = false;
      isBank = true;
      isPosCard = false;
    } else if (vm.paymentMethod == 'THE') {
      isCash = false;
      isBank = false;
      isPosCard = true;
    }

    BankModel? chosenBank = vm.selectedBank ?? (vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null);
    BankModel? chosenCardBank = vm.selectedBank ?? (vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null);
    
    // Controller nhập số tiền khách trả
    final TextEditingController paidCtrl = TextEditingController(text: Formatters.formatNumber(subtotal));
    final TextEditingController cashPartCtrl = TextEditingController(text: Formatters.formatNumber(subtotal));
    final TextEditingController bankPartCtrl = TextEditingController(text: '0');
    final TextEditingController cardPartCtrl = TextEditingController(text: '0');
    bool applySurplusToDebt = true;

    // Tự động phân bổ số tiền khi thay đổi các checkbox phương thức thanh toán
    void autoDistributeAmounts() {
      final selected = <String>[];
      if (isCash) selected.add('cash');
      if (isBank) selected.add('bank');
      if (isPosCard) selected.add('card');

      if (selected.isEmpty) {
        paidCtrl.text = '0';
        cashPartCtrl.text = '0';
        bankPartCtrl.text = '0';
        cardPartCtrl.text = '0';
        return;
      }

      if (selected.length == 1) {
        final fullStr = Formatters.formatNumber(subtotal);
        paidCtrl.text = fullStr;
        if (isCash) {
          cashPartCtrl.text = fullStr;
          bankPartCtrl.text = '0';
          cardPartCtrl.text = '0';
        } else if (isBank) {
          bankPartCtrl.text = fullStr;
          cashPartCtrl.text = '0';
          cardPartCtrl.text = '0';
        } else if (isPosCard) {
          cardPartCtrl.text = fullStr;
          cashPartCtrl.text = '0';
          bankPartCtrl.text = '0';
        }
      } else if (selected.length == 2) {
        final half = (subtotal / 2).floorToDouble();
        final rem = subtotal - half;
        final halfStr = Formatters.formatNumber(half);
        final remStr = Formatters.formatNumber(rem);
        if (isCash && isBank) {
          cashPartCtrl.text = halfStr;
          bankPartCtrl.text = remStr;
          cardPartCtrl.text = '0';
        } else if (isCash && isPosCard) {
          cashPartCtrl.text = halfStr;
          cardPartCtrl.text = remStr;
          bankPartCtrl.text = '0';
        } else if (isBank && isPosCard) {
          bankPartCtrl.text = halfStr;
          cardPartCtrl.text = remStr;
          cashPartCtrl.text = '0';
        }
      } else if (selected.length == 3) {
        final third = (subtotal / 3).floorToDouble();
        final rem = subtotal - (third * 2);
        cashPartCtrl.text = Formatters.formatNumber(third);
        bankPartCtrl.text = Formatters.formatNumber(third);
        cardPartCtrl.text = Formatters.formatNumber(rem);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int selectedCount = (isCash ? 1 : 0) + (isBank ? 1 : 0) + (isPosCard ? 1 : 0);
            final bool isCombined = selectedCount >= 2;

            // Xác định mã hình thức thanh toán chuẩn
            String pMethod;
            if (isDebtOnly) {
              pMethod = 'CON_NO';
            } else if (isCombined) {
              pMethod = 'HON_HOP';
            } else if (isCash) {
              pMethod = 'TIEN_MAT';
            } else if (isBank) {
              pMethod = 'TAI_KHOAN';
            } else if (isPosCard) {
              pMethod = 'THE';
            } else {
              pMethod = 'TIEN_MAT';
            }

            // Tính toán số tiền khách trả thực tế
            double actualPaid = 0.0;
            if (isDebtOnly) {
              actualPaid = 0.0;
            } else if (isCombined) {
              final c = isCash ? Formatters.parseCurrency(cashPartCtrl.text) : 0.0;
              final b = isBank ? Formatters.parseCurrency(bankPartCtrl.text) : 0.0;
              final p = isPosCard ? Formatters.parseCurrency(cardPartCtrl.text) : 0.0;
              actualPaid = c + b + p;
            } else {
              actualPaid = Formatters.parseCurrency(paidCtrl.text);
            }

            final diff = actualPaid - subtotal; // < 0: thiếu (nợ); > 0: thừa
            final isShort = diff < 0;
            final isOver = diff > 0;
            final shortAmount = -diff;
            final overAmount = diff;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Xác nhận thanh toán POS',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Khối 1: Thông tin khách hàng & Chi nhánh
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Chi nhánh: ${branchVm.selectedBranch.displayName}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_outlined, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Khách hàng: ${vm.selectedCustomer?.tenDoiTac ?? "Khách lẻ"}'
                                  '${vm.selectedCustomer != null ? " (Nợ: ${Formatters.formatCurrency(vm.selectedCustomer!.congNo)})" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: vm.selectedCustomer != null ? AppTheme.primaryBlue : Colors.black87,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _showCustomerSelectorBottomSheet(context, vm);
                                  setModalState(() {});
                                },
                                child: Text(
                                  vm.selectedCustomer != null ? 'Đổi' : 'Chọn khách',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Khối 2: Chi tiết giỏ hàng tóm tắt (Cho phép chỉnh sửa giá và số lượng trực tiếp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Chi tiết sản phẩm đơn hàng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showCartBottomSheet(context, vm, branchVm);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.edit_note, size: 16, color: AppTheme.primaryBlue),
                              SizedBox(width: 2),
                              Text('Sửa giỏ', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: vm.cart.length,
                        itemBuilder: (context, index) {
                          final item = vm.cart[index];
                          return InkWell(
                            onTap: () {
                              _showEditCartItemDialog(context, vm, item, () {
                                setModalState(() {
                                  if (pMethod != 'CON_NO' && pMethod != 'HON_HOP') {
                                    paidCtrl.text = vm.subtotal.toInt().toString();
                                  }
                                });
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryBlue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.tenHang, 
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text('x${item.soLuong}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Formatters.formatCurrency(item.thanhTien),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),

                    // Khối 3: Hình thức thanh toán dạng CHECKBOX (Tiền mặt, Ngân hàng, Thẻ POS & Kết hợp cả 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hình thức thanh toán (Tích chọn):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (isCombined)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.splitscreen_outlined, size: 12, color: Colors.brown),
                                const SizedBox(width: 4),
                                Text(
                                  'Kết hợp ($selectedCount phương thức)',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hàng 3 Checkbox: Tiền mặt • Ngân hàng • Thẻ POS
                    Row(
                      children: [
                        // Checkbox 1: Tiền mặt
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                isDebtOnly = false;
                                if (isCash && (isBank || isPosCard)) {
                                  isCash = false;
                                } else {
                                  isCash = true;
                                }
                                autoDistributeAmounts();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isCash && !isDebtOnly) ? const Color(0xFFF0FDFA) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isCash && !isDebtOnly) ? const Color(0xFF0D9488) : Colors.grey.shade300,
                                  width: (isCash && !isDebtOnly) ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payments_outlined, size: 16, color: (isCash && !isDebtOnly) ? const Color(0xFF0D9488) : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: isCash && !isDebtOnly,
                                          activeColor: const Color(0xFF0D9488),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (_) {
                                            setModalState(() {
                                              isDebtOnly = false;
                                              if (isCash && (isBank || isPosCard)) {
                                                isCash = false;
                                              } else {
                                                isCash = true;
                                              }
                                              autoDistributeAmounts();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tiền mặt',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: (isCash && !isDebtOnly) ? FontWeight.bold : FontWeight.w600,
                                      color: (isCash && !isDebtOnly) ? const Color(0xFF0D9488) : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Checkbox 2: Ngân hàng (Chuyển khoản)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                isDebtOnly = false;
                                if (isBank && (isCash || isPosCard)) {
                                  isBank = false;
                                } else {
                                  isBank = true;
                                }
                                autoDistributeAmounts();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isBank && !isDebtOnly) ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isBank && !isDebtOnly) ? AppTheme.primaryBlue : Colors.grey.shade300,
                                  width: (isBank && !isDebtOnly) ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.account_balance_outlined, size: 16, color: (isBank && !isDebtOnly) ? AppTheme.primaryBlue : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: isBank && !isDebtOnly,
                                          activeColor: AppTheme.primaryBlue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (_) {
                                            setModalState(() {
                                              isDebtOnly = false;
                                              if (isBank && (isCash || isPosCard)) {
                                                isBank = false;
                                              } else {
                                                isBank = true;
                                              }
                                              autoDistributeAmounts();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ngân hàng',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: (isBank && !isDebtOnly) ? FontWeight.bold : FontWeight.w600,
                                      color: (isBank && !isDebtOnly) ? AppTheme.primaryBlue : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Checkbox 3: Quẹt thẻ POS
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                isDebtOnly = false;
                                if (isPosCard && (isCash || isBank)) {
                                  isPosCard = false;
                                } else {
                                  isPosCard = true;
                                }
                                autoDistributeAmounts();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isPosCard && !isDebtOnly) ? const Color(0xFFFAF5FF) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isPosCard && !isDebtOnly) ? const Color(0xFF9333EA) : Colors.grey.shade300,
                                  width: (isPosCard && !isDebtOnly) ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.credit_card_outlined, size: 16, color: (isPosCard && !isDebtOnly) ? const Color(0xFF9333EA) : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: isPosCard && !isDebtOnly,
                                          activeColor: const Color(0xFF9333EA),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (_) {
                                            setModalState(() {
                                              isDebtOnly = false;
                                              if (isPosCard && (isCash || isBank)) {
                                                isPosCard = false;
                                              } else {
                                                isPosCard = true;
                                              }
                                              autoDistributeAmounts();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Thẻ POS',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: (isPosCard && !isDebtOnly) ? FontWeight.bold : FontWeight.w600,
                                      color: (isPosCard && !isDebtOnly) ? const Color(0xFF9333EA) : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tùy chọn Ghi nợ phụ (Nợ toàn bộ 100%)
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          isDebtOnly = !isDebtOnly;
                          if (isDebtOnly) {
                            paidCtrl.text = '0';
                            cashPartCtrl.text = '0';
                            bankPartCtrl.text = '0';
                            cardPartCtrl.text = '0';
                          } else {
                            isCash = true;
                            autoDistributeAmounts();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: isDebtOnly,
                                activeColor: AppTheme.warningOrange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setModalState(() {
                                    isDebtOnly = val ?? false;
                                    if (isDebtOnly) {
                                      paidCtrl.text = '0';
                                      cashPartCtrl.text = '0';
                                      bankPartCtrl.text = '0';
                                      cardPartCtrl.text = '0';
                                    } else {
                                      isCash = true;
                                      autoDistributeAmounts();
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Khách nợ toàn bộ 100% (chưa thanh toán)',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Khối 4 & 5: Nhập số tiền chi tiết cho từng hình thức
                    if (isCombined && !isDebtOnly) ...[
                      // KHỐI PHÂN BỔ TIỀN KHI CHỌN TỪ 2 HOẶC CẢ 3 HÌNH THỨC
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Chia tiền theo phương thức đã chọn:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                                InkWell(
                                  onTap: () => setModalState(() => autoDistributeAmounts()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Chia đều', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 1. Ô tiền mặt
                            if (isCash) ...[
                              TextField(
                                controller: cashPartCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: '💵 Tiền mặt (đ)',
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.payments, size: 16, color: Color(0xFF0D9488)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // 2. Ô ngân hàng + Dropdown chọn ngân hàng
                            if (isBank) ...[
                              TextField(
                                controller: bankPartCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: '🏦 Chuyển khoản ngân hàng (đ)',
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.account_balance, size: 16, color: AppTheme.primaryBlue),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<BankModel>(
                                isExpanded: true,
                                value: chosenBank,
                                decoration: InputDecoration(
                                  labelText: 'Tài khoản ngân hàng nhận tiền',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: vm.bankAccounts.map((b) {
                                  return DropdownMenuItem<BankModel>(
                                    value: b,
                                    child: Text(
                                      b.displayName,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newBank) => setModalState(() => chosenBank = newBank),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // 3. Ô quẹt thẻ POS + Dropdown chọn tài khoản thẻ
                            if (isPosCard) ...[
                              TextField(
                                controller: cardPartCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: '💳 Quẹt thẻ POS (đ)',
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.credit_card, size: 16, color: Color(0xFF9333EA)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<BankModel>(
                                isExpanded: true,
                                value: chosenCardBank,
                                decoration: InputDecoration(
                                  labelText: 'Tài khoản thẻ POS nhận',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: vm.bankAccounts.map((b) {
                                  return DropdownMenuItem<BankModel>(
                                    value: b,
                                    child: Text(
                                      '💳 Thẻ POS: ${b.displayName}',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newBank) => setModalState(() => chosenCardBank = newBank),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else if (!isDebtOnly) ...[
                      // KHI CHỈ CHỌN 1 HÌNH THỨC DUY NHẤT
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: paidCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: isCash 
                                    ? 'Số tiền mặt thanh toán (VNĐ)' 
                                    : (isBank ? 'Số tiền chuyển khoản (VNĐ)' : 'Số tiền quẹt thẻ POS (VNĐ)'),
                                prefixIcon: Icon(
                                  isCash ? Icons.payments_outlined : (isBank ? Icons.account_balance_outlined : Icons.credit_card_outlined),
                                  color: isCash ? const Color(0xFF0D9488) : (isBank ? AppTheme.primaryBlue : const Color(0xFF9333EA)),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixText: 'đ',
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setModalState(() {
                                paidCtrl.text = Formatters.formatNumber(subtotal);
                              });
                            },
                            child: const Text('Đúng tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dropdown ngân hàng nếu là Chuyển khoản
                      if (isBank) ...[
                        DropdownButtonFormField<BankModel>(
                          isExpanded: true,
                          value: chosenBank,
                          decoration: InputDecoration(
                            labelText: 'Tài khoản ngân hàng nhận tiền (*)',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: vm.bankAccounts.map((b) {
                            return DropdownMenuItem<BankModel>(
                              value: b,
                              child: Text(
                                b.displayName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newBank) => setModalState(() => chosenBank = newBank),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Dropdown tài khoản thẻ nếu là Quẹt thẻ POS
                      if (isPosCard) ...[
                        DropdownButtonFormField<BankModel>(
                          isExpanded: true,
                          value: chosenCardBank,
                          decoration: InputDecoration(
                            labelText: 'Tài khoản thẻ POS nhận tiền (*)',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: vm.bankAccounts.map((b) {
                            return DropdownMenuItem<BankModel>(
                              value: b,
                              child: Text(
                                '💳 Thẻ POS: ${b.displayName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newBank) => setModalState(() => chosenCardBank = newBank),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],

                    // Khối 6: Bảng tính toán chênh lệch & Thông báo công nợ / tiền thừa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isShort 
                            ? Colors.amber.shade50 
                            : isOver 
                                ? Colors.green.shade50 
                                : Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isShort 
                              ? Colors.amber.shade400 
                              : isOver 
                                  ? Colors.green.shade400 
                                  : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng tiền hàng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(
                                Formatters.formatCurrency(subtotal),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Khách thanh toán:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(
                                Formatters.formatCurrency(actualPaid),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          // Hiển thị trạng thái thiếu / thừa
                          if (isShort) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '👉 Khách còn thiếu:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                                ),
                                Text(
                                  Formatters.formatCurrency(shortAmount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vm.selectedCustomer != null
                                    ? '⚡ Khoản thiếu ${Formatters.formatCurrency(shortAmount)} sẽ được CỘNG VÀO CÔNG NỢ của [${vm.selectedCustomer!.tenDoiTac}]'
                                    : '⚠️ CHÚ Ý: Bạn phải chọn khách hàng cụ thể để ghi nhận nợ khoản tiền này!',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: vm.selectedCustomer != null ? Colors.brown.shade900 : AppTheme.dangerRed,
                                ),
                              ),
                            ),
                          ] else if (isOver) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '👉 Tiền thừa trả khách:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                ),
                                Text(
                                  Formatters.formatCurrency(overAmount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                ),
                              ],
                            ),
                            if (vm.selectedCustomer != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: applySurplusToDebt,
                                      onChanged: (val) {
                                        setModalState(() {
                                          applySurplusToDebt = val ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cấn trừ ${Formatters.formatCurrency(overAmount)} vào công nợ cũ của khách',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
                                SizedBox(width: 6),
                                Text(
                                  'Đã thanh toán đủ 100%',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút Hoàn Tất Thanh Toán
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: vm.isLoading ? null : () async {
                          // Kiểm tra ràng buộc ghi nợ
                          if (isShort && vm.selectedCustomer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Khách hàng trả thiếu ${Formatters.formatCurrency(shortAmount)}. Vui lòng chọn khách hàng để ghi nợ!'),
                                backgroundColor: AppTheme.dangerRed,
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'Chọn khách',
                                  textColor: Colors.white,
                                  onPressed: () => _showCustomerSelectorBottomSheet(context, vm),
                                ),
                              ),
                            );
                            return;
                          }

                          final cashVal = isDebtOnly
                              ? 0.0
                              : (isCombined
                                  ? (isCash ? Formatters.parseCurrency(cashPartCtrl.text) : 0.0)
                                  : (isCash ? actualPaid : 0.0));
                          final bankVal = isDebtOnly
                              ? 0.0
                              : (isCombined
                                  ? (isBank ? Formatters.parseCurrency(bankPartCtrl.text) : 0.0)
                                  : (isBank ? actualPaid : 0.0));
                          final cardVal = isDebtOnly
                              ? 0.0
                              : (isCombined
                                  ? (isPosCard ? Formatters.parseCurrency(cardPartCtrl.text) : 0.0)
                                  : (isPosCard ? actualPaid : 0.0));

                          final res = await vm.checkout(
                            chiNhanh: branchVm.selectedBranch.displayName,
                            customerPaid: actualPaid,
                            paymentMethod: pMethod,
                            bankAccount: chosenBank,
                            cardBankAccount: chosenCardBank,
                            cashAmount: cashVal,
                            bankTransferAmount: bankVal,
                            cardAmount: cardVal,
                            applySurplusToDebt: applySurplusToDebt,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? (res['success'] == true ? '✅ Thanh toán thành công!' : '❌ Có lỗi xảy ra')),
                                backgroundColor: res['success'] == true ? AppTheme.successGreen : AppTheme.dangerRed,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: vm.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('HOÀN TẤT VÀ IN HÓA ĐƠN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _openBarcodeScanner(BuildContext context, PosViewModel vm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dlgContext) => BarcodeScannerDialog(
        onScanned: (code) {
          _searchCtrl.text = code;
          vm.searchProducts(code);
          setState(() {});

          final product = vm.findProductByBarcode(code);
          if (product != null) {
            vm.addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã thêm "${product.tenHang}" (${product.maHang}) vào đơn hàng!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.successGreen,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Đã quét mã: "$code" (Đã lọc danh sách sản phẩm)'),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primaryBlue,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  // Dialog chỉnh sửa giá bán và số lượng của 1 mặt hàng trong giỏ
  void _showEditCartItemDialog(BuildContext context, PosViewModel vm, OrderItemModel item, [VoidCallback? onUpdated]) {
    final qtyCtrl = TextEditingController(text: item.soLuong.toString());
    final priceCtrl = TextEditingController(text: Formatters.formatNumber(item.donGia));
    final imeiCtrl = TextEditingController(text: item.imeiStr);

    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.tenHang,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã sản phẩm: ${item.maHang}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá bán (VNĐ)',
                    hintText: 'Nhập giá bán mới...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng đặt mua',
                    hintText: 'Nhập số lượng...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers_outlined, size: 20),
                    isDense: true,
                  ),
                ),
                if (item.coQuanLyImei) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: imeiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IMEI / Serial (tùy chọn)',
                      hintText: 'Nhập IMEI gắn với máy...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_2_outlined, size: 20),
                      isDense: true,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Không quản lý IMEI',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 18),
              label: const Text('Xóa khỏi giỏ', style: TextStyle(color: AppTheme.dangerRed)),
              onPressed: () {
                vm.removeFromCart(item.maHang);
                Navigator.pop(dCtx);
                if (onUpdated != null) onUpdated();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newQty = int.tryParse(qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                final newPrice = Formatters.parseCurrency(priceCtrl.text);
                final newImei = item.coQuanLyImei ? imeiCtrl.text.trim() : '';

                vm.updateCartItem(
                  item.maHang,
                  quantity: newQty,
                  price: newPrice > 0 ? newPrice : item.donGia,
                  imeiStr: newImei,
                );
                Navigator.pop(dCtx);
                if (onUpdated != null) onUpdated();
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );
  }

  // BottomSheet chi tiết giỏ hàng: xem, đổi số lượng, sửa đơn giá, xóa mặt hàng
  void _showCartBottomSheet(BuildContext context, PosViewModel vm, BranchViewModel branchVm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Giỏ hàng (${vm.totalItemCount} sản phẩm)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (vm.cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Giỏ hàng đang trống')),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: vm.cart.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = vm.cart[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.tenHang,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          _showEditCartItemDialog(context, vm, item, () {
                                            setSheetState(() {});
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Đơn giá: ${Formatters.formatCurrency(item.donGia)}',
                                              style: const TextStyle(
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryBlue),
                                          ],
                                        ),
                                      ),
                                      if (item.coQuanLyImei && item.imeiStr.isNotEmpty)
                                        Text('IMEI: ${item.imeiStr}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))
                                      else if (!item.coQuanLyImei)
                                        const Text('Không quản lý IMEI', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                // Bộ tăng giảm số lượng & sửa trực tiếp
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textMuted, size: 22),
                                      onPressed: () {
                                        vm.updateQuantity(item.maHang, -1);
                                        setSheetState(() {});
                                      },
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _showEditCartItemDialog(context, vm, item, () {
                                          setSheetState(() {});
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: Text(
                                          '${item.soLuong}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 22),
                                      onPressed: () {
                                        vm.updateQuantity(item.maHang, 1);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(item.thanhTien),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerRed),
                                      tooltip: 'Xóa',
                                      onPressed: () {
                                        vm.removeFromCart(item.maHang);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        Formatters.formatCurrency(vm.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('TIẾN HÀNH THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: vm.cart.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _showCheckoutModal(context, vm, branchVm);
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Widget Modal Quét Mã Vạch / QR Sản Phẩm Bằng Camera
class BarcodeScannerDialog extends StatefulWidget {
  final Function(String code) onScanned;

  const BarcodeScannerDialog({super.key, required this.onScanned});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        setState(() {
          _isScanned = true;
        });
        widget.onScanned(code.trim());
        Navigator.of(context).pop();
        break;
      }
    }
  }

  void _showManualInputDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (mCtx) => AlertDialog(
        title: const Text('Nhập mã sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập mã vạch hoặc mã hàng...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(mCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(mCtx);
                widget.onScanned(val);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 520,
        child: Stack(
          children: [
            // 1. Camera Viewfinder
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // 2. Scan Frame Overlay
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner accents
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.successGreen, width: 4),
                            left: BorderSide(color: AppTheme.successGreen, width: 4),
                          ),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.successGreen, width: 4),
                            right: BorderSide(color: AppTheme.successGreen, width: 4),
                          ),
                          borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.successGreen, width: 4),
                            left: BorderSide(color: AppTheme.successGreen, width: 4),
                          ),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.successGreen, width: 4),
                            right: BorderSide(color: AppTheme.successGreen, width: 4),
                          ),
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                        ),
                      ),
                    ),
                    // Red laser guideline in center
                    Center(
                      child: Container(
                        height: 2,
                        width: 230,
                        color: Colors.redAccent.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top Control Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black.withOpacity(0.55),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quét mã vạch / QR sản phẩm',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _torchOn ? Icons.flash_on : Icons.flash_off,
                        color: _torchOn ? Colors.amber : Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Bật/Tắt đèn Flash',
                      onPressed: () async {
                        try {
                          await _controller.toggleTorch();
                          if (mounted) {
                            setState(() {
                              _torchOn = !_torchOn;
                            });
                          }
                        } catch (e) {
                          debugPrint("Lỗi bật flash: $e");
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                      tooltip: 'Đổi Camera trước/sau',
                      onPressed: () async {
                        try {
                          await _controller.switchCamera();
                        } catch (e) {
                          debugPrint("Lỗi đổi camera: $e");
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Instruction Bar & Manual Input Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hướng máy ảnh vào mã vạch hoặc mã QR trên sản phẩm',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.keyboard, size: 16),
                      label: const Text('Nhập mã thủ công', style: TextStyle(fontSize: 12)),
                      onPressed: _showManualInputDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
