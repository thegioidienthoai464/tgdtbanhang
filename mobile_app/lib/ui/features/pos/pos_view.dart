import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/bank_model.dart';
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
                                    '• Tồn: ${p.tonKho.toInt()}',
                                    style: TextStyle(
                                      color: p.tonKho > 0 ? AppTheme.textMuted : AppTheme.dangerRed,
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
                          final debt = double.tryParse(debtCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;

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

  // Modal Xác Nhận Thanh Toán Toàn Diện
  void _showCheckoutModal(BuildContext context, PosViewModel vm, BranchViewModel branchVm) {
    final subtotal = vm.subtotal;
    
    // State cục bộ cho modal thanh toán
    String pMethod = vm.paymentMethod;
    BankModel? chosenBank = vm.selectedBank ?? (vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null);
    
    // Controller nhập số tiền khách trả
    final TextEditingController paidCtrl = TextEditingController(text: subtotal.toInt().toString());
    final TextEditingController cashPartCtrl = TextEditingController(text: (subtotal / 2).toInt().toString());
    final TextEditingController bankPartCtrl = TextEditingController(text: (subtotal - (subtotal / 2).toInt()).toInt().toString());
    bool applySurplusToDebt = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Tính toán số tiền khách trả theo hình thức
            double actualPaid = 0.0;
            if (pMethod == 'CON_NO') {
              actualPaid = 0.0;
            } else if (pMethod == 'HON_HOP') {
              final c = double.tryParse(cashPartCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              final b = double.tryParse(bankPartCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
              actualPaid = c + b;
            } else {
              actualPaid = double.tryParse(paidCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
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

                    // Khối 3: Hình thức thanh toán (4 tùy chọn)
                    const Text('Hình thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('Tiền mặt'),
                          selected: pMethod == 'TIEN_MAT',
                          onSelected: (_) {
                            setModalState(() {
                              pMethod = 'TIEN_MAT';
                              paidCtrl.text = subtotal.toInt().toString();
                            });
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.account_balance_outlined, size: 16),
                          label: const Text('Chuyển khoản'),
                          selected: pMethod == 'TAI_KHOAN',
                          onSelected: (_) {
                            setModalState(() {
                              pMethod = 'TAI_KHOAN';
                              paidCtrl.text = subtotal.toInt().toString();
                            });
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.splitscreen_outlined, size: 16),
                          label: const Text('Hỗn hợp (TM + CK)'),
                          selected: pMethod == 'HON_HOP',
                          onSelected: (_) {
                            setModalState(() {
                              pMethod = 'HON_HOP';
                              cashPartCtrl.text = (subtotal / 2).toInt().toString();
                              bankPartCtrl.text = (subtotal - (subtotal / 2).toInt()).toInt().toString();
                            });
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.edit_note_outlined, size: 16),
                          label: const Text('Ghi nợ'),
                          selected: pMethod == 'CON_NO',
                          onSelected: (_) {
                            setModalState(() {
                              pMethod = 'CON_NO';
                              paidCtrl.text = '0';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Khối 4: Tùy chọn Tài khoản ngân hàng (nếu là TAI_KHOAN hoặc HON_HOP)
                    if (pMethod == 'TAI_KHOAN' || pMethod == 'HON_HOP') ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance, size: 16, color: AppTheme.primaryBlue),
                                SizedBox(width: 6),
                                Text(
                                  'Tài khoản ngân hàng nhận tiền (*):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (vm.bankAccounts.isEmpty)
                              const Text('Chưa có danh sách ngân hàng trong hệ thống', style: TextStyle(fontSize: 12, color: Colors.grey))
                            else
                              DropdownButtonFormField<BankModel>(
                                isExpanded: true,
                                value: chosenBank,
                                decoration: InputDecoration(
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
                                onChanged: (newBank) {
                                  setModalState(() {
                                    chosenBank = newBank;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Khối 5: Nhập số tiền chi tiết cho từng hình thức
                    if (pMethod == 'HON_HOP') ...[
                      // Hai ô nhập tiền mặt & chuyển khoản cho thanh toán hỗn hợp
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cashPartCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Tiền mặt (đ)',
                                isDense: true,
                                prefixIcon: const Icon(Icons.payments, size: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: bankPartCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Chuyển khoản (đ)',
                                isDense: true,
                                prefixIcon: const Icon(Icons.account_balance, size: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else if (pMethod != 'CON_NO') ...[
                      // Ô nhập số tiền khách trả tùy chỉnh
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: paidCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số tiền khách thanh toán (VNĐ)',
                                prefixIcon: const Icon(Icons.attach_money),
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
                                paidCtrl.text = subtotal.toInt().toString();
                              });
                            },
                            child: const Text('Đúng tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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

                          final cashVal = pMethod == 'HON_HOP' 
                              ? (double.tryParse(cashPartCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0)
                              : (pMethod == 'TIEN_MAT' ? actualPaid : 0.0);
                          final bankVal = pMethod == 'HON_HOP' 
                              ? (double.tryParse(bankPartCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0)
                              : (pMethod == 'TAI_KHOAN' ? actualPaid : 0.0);

                          final res = await vm.checkout(
                            chiNhanh: branchVm.selectedBranch.displayName,
                            customerPaid: actualPaid,
                            paymentMethod: pMethod,
                            bankAccount: chosenBank,
                            cashAmount: cashVal,
                            bankTransferAmount: bankVal,
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
