import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  backgroundColor: vm.selectedCustomer != null 
                      ? AppTheme.primaryBlue.withOpacity(0.12) 
                      : Colors.grey.shade100,
                  child: Icon(
                    vm.selectedCustomer != null ? Icons.person : Icons.person_outline,
                    size: 18,
                    color: vm.selectedCustomer != null ? AppTheme.primaryBlue : AppTheme.textMuted,
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
                              vm.selectedCustomer?.tenDoiTac ?? 'Khách lẻ (Mặc định)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: vm.selectedCustomer != null ? AppTheme.primaryBlue : Colors.black87,
                              ),
                            ),
                            if (vm.selectedCustomer != null && vm.selectedCustomer!.soDienThoai.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${vm.selectedCustomer!.soDienThoai}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ],
                        ),
                        if (vm.selectedCustomer != null)
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
                            'Chạm để chọn khách quen hoặc ghi nhận nợ',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
                if (vm.selectedCustomer != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                    tooltip: 'Đổi về Khách lẻ',
                    onPressed: () => vm.setCustomer(null),
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.person_search_outlined, size: 16),
                    label: const Text('Chọn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showCustomerSelectorBottomSheet(context, vm),
                  ),
              ],
            ),
          ),

          // 3. Thanh tìm kiếm sản phẩm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên, mã sản phẩm...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
              ),
              onChanged: vm.searchProducts,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${vm.totalItemCount} sản phẩm • ${vm.selectedCustomer?.tenDoiTac ?? "Khách lẻ"}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person_off_outlined, color: Colors.grey),
                    ),
                    title: const Text('Khách lẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Mặc định (Không ghi nợ)', style: TextStyle(fontSize: 12)),
                    trailing: vm.selectedCustomer == null 
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
  void _showQuickAddCustomerDialog(BuildContext context, PosViewModel vm, StateSetter parentSetState) {
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
                            parentSetState(() {});
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

                    // Khối 2: Chi tiết giỏ hàng tóm tắt
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: vm.cart.length,
                        itemBuilder: (context, index) {
                          final item = vm.cart[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.tenHang, 
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text('x${item.soLuong}  ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  Formatters.formatCurrency(item.thanhTien),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
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
}
