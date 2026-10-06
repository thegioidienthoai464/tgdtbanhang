import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu ngân POS'),
        actions: [
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
          // Thanh tìm kiếm sản phẩm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Danh sách sản phẩm
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
                              border: Border.Border.all(
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

          // Thanh tóm tắt giỏ hàng phía dưới
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
                            '${vm.totalItemCount} sản phẩm',
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
                      onPressed: () => _showCheckoutModal(context, vm),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCheckoutModal(BuildContext context, PosViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Xác nhận đơn hàng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Chi tiết giỏ hàng
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: vm.cart.length,
                      itemBuilder: (context, index) {
                        final item = vm.cart[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.tenHang, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  vm.updateQuantity(item.maHang, -1);
                                  setModalState(() {});
                                },
                              ),
                              Text('${item.soLuong}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  vm.updateQuantity(item.maHang, 1);
                                  setModalState(() {});
                                },
                              ),
                              Text(
                                Formatters.formatCurrency(item.thanhTien),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(),
                  
                  // Phương thức thanh toán
                  const Text('Hình thức thanh toán:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tiền mặt'),
                        selected: vm.paymentMethod == 'TIEN_MAT',
                        onSelected: (_) {
                          vm.setPaymentMethod('TIEN_MAT');
                          setModalState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Chuyển khoản'),
                        selected: vm.paymentMethod == 'TAI_KHOAN',
                        onSelected: (_) {
                          vm.setPaymentMethod('TAI_KHOAN');
                          setModalState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Ghi nợ khách'),
                        selected: vm.paymentMethod == 'CON_NO',
                        onSelected: (_) {
                          vm.setPaymentMethod('CON_NO');
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        Formatters.formatCurrency(vm.subtotal),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : () async {
                        final success = await vm.checkout();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? '✅ Thanh toán thành công!' : '❌ Có lỗi xảy ra'),
                              backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
                            ),
                          );
                        }
                      },
                      child: vm.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('HOÀN TẤT VÀ IN HÓA ĐƠN', style: TextStyle(fontSize: 16)),
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
