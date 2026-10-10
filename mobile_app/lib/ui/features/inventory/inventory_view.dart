import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../branch/branch_view_model.dart';
import '../branch/branch_filter_chips.dart';
import '../../../data/models/product_model.dart';
import 'inventory_view_model.dart';


class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryViewModel>().fetchInventory();
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho & IMEI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 24),
            tooltip: 'Thêm hàng hóa mới',
            onPressed: () => _showProductFormDialog(context, vm, branchVm),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.fetchInventory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm hàng hóa'),
        onPressed: () => _showProductFormDialog(context, vm, branchVm),
      ),
      body: Column(
        children: [
          // Thanh chi nhánh kho
          InkWell(
            onTap: () => BranchViewModel.showBranchBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.06),
                border: Border(bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.12))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chi nhánh kho: ${branchVm.summaryDisplayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: BranchFilterChips(),
          ),
          // Thống kê nhanh tổng tồn

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Tổng số lượng', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${currentTotalStock.toInt()} cái',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Column(
                  children: [
                    const Text('Tổng giá trị vốn', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(currentTotalValue),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hoặc tên sản phẩm...',
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
              onChanged: vm.search,
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách tồn kho
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.products.isEmpty
                    ? const Center(child: Text('Không có hàng hóa nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: vm.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = vm.products[index];
                          final pStock = p.getTonKhoChoBoLoc(branchVm.selectedBranchCodes, branchVm.isAllSelected);
                          final hasStock = pStock > 0;
                          final pGiaVon = p.getGiaVonTaiChiNhanh(branchVm.selectedBranch.maCN);
                          final pImeis = p.getImeisTaiChiNhanh(branchVm.selectedBranch.maCN);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: ListTile(
                              onTap: () => _showProductFormDialog(context, vm, branchVm, product: p),
                              leading: CircleAvatar(
                                backgroundColor: hasStock ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
                                child: Text(
                                  '${pStock.toInt()}',
                                  style: TextStyle(
                                    color: hasStock ? AppTheme.successGreen : AppTheme.dangerRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                p.tenHang,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${p.maHang} • Vốn: ${Formatters.formatCurrency(pGiaVon)} • Giá: ${Formatters.formatCurrency(p.giaBan)}${p.coQuanLyImei ? " • 📱 ${pImeis.length} IMEI" : ""}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              trailing: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Dialog Thêm mới hoặc Chỉnh sửa thông tin hàng hóa
  void _showProductFormDialog(
    BuildContext context,
    InventoryViewModel vm,
    BranchViewModel branchVm, {
    ProductModel? product,
  }) {
    final isEdit = product != null;
    final now = DateTime.now();
    final defaultCode = isEdit ? product.maHang : "SP${now.millisecondsSinceEpoch.toString().substring(7)}";

    final codeCtrl = TextEditingController(text: defaultCode);
    final nameCtrl = TextEditingController(text: isEdit ? product.tenHang : '');
    final groupCtrl = TextEditingController(text: isEdit ? product.maNhom : 'Điện thoại');
    final unitCtrl = TextEditingController(text: isEdit ? product.donViTinh : 'Cái');
    final costCtrl = TextEditingController(text: isEdit ? product.giaVon.toInt().toString() : '0');
    final priceCtrl = TextEditingController(text: isEdit ? product.giaBan.toInt().toString() : '0');
    final stockCtrl = TextEditingController(text: isEdit ? product.tonKho.toInt().toString() : '1');
    final branchCtrl = TextEditingController(text: isEdit ? product.chiNhanh : branchVm.selectedBranch.displayName);

    bool imeiManaged = isEdit ? product.coQuanLyImei : false;
    String status = isEdit ? product.trangThai : 'Kinh doanh';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                          child: Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Chỉnh sửa hàng hóa' : 'Thêm mới hàng hóa',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              Text(
                                isEdit ? 'Cập nhật giá bán, giá vốn, tồn kho & thông tin' : 'Nhập thông tin sản phẩm mới vào kho ERP',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                    const Divider(height: 24),

                    // 1. Mã hàng & Tên hàng
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: codeCtrl,
                            enabled: !isEdit, // Mã hàng là khóa chính khi sửa
                            decoration: InputDecoration(
                              labelText: 'Mã hàng (*)',
                              hintText: 'VD: IP15PM',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              filled: isEdit,
                              fillColor: isEdit ? Colors.grey.shade100 : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: nameCtrl,
                            autofocus: !isEdit,
                            decoration: const InputDecoration(
                              labelText: 'Tên hàng hóa (*)',
                              hintText: 'VD: iPhone 15 Pro Max 256GB',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Nhóm hàng & Đơn vị tính
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: groupCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nhóm hàng',
                              hintText: 'VD: Điện thoại, Phụ kiện...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Đơn vị tính',
                              hintText: 'Cái / Bộ / Máy...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Giá vốn nhập & Giá bán niêm yết
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá vốn nhập (VNĐ)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.money_off_csred_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá bán ra (VNĐ)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.attach_money_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Tồn kho & Chi nhánh
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng tồn kho',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: branchCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Chi nhánh lưu kho',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.storefront_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Cấu hình Quản lý IMEI & Trạng thái kinh doanh
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_2, size: 20, color: AppTheme.primaryBlue),
                                  SizedBox(width: 8),
                                  Text('Quản lý theo IMEI / Serial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Switch(
                                value: imeiManaged,
                                activeColor: AppTheme.primaryBlue,
                                onChanged: (val) => setSheetState(() => imeiManaged = val),
                              ),
                            ],
                          ),
                          const Divider(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trạng thái kinh doanh:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              DropdownButton<String>(
                                value: status,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'Kinh doanh', child: Text('Kinh doanh', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'Ngừng kinh doanh', child: Text('Ngừng kinh doanh', style: TextStyle(color: AppTheme.dangerRed))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => status = val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6. Action buttons (Lưu, Hủy, Xóa nếu là Edit)
                    Row(
                      children: [
                        if (isEdit) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
                            tooltip: 'Xóa hàng hóa',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Xác nhận xóa hàng hóa?'),
                                  content: Text('Bạn có chắc chắn muốn xóa "${product.tenHang}" (${product.maHang}) khỏi danh mục kho?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                      onPressed: () async {
                                        Navigator.pop(c); // Đóng dialog
                                        Navigator.pop(ctx); // Đóng bottom sheet
                                        final ok = await vm.deleteProduct(product.maHang);
                                        if (ok) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Đã xóa thành công ${product.tenHang}!'), backgroundColor: AppTheme.dangerRed),
                                          );
                                        }
                                      },
                                      child: const Text('XÓA VĨNH VIỄN'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
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
                            label: Text(
                              isEdit ? 'LƯU THAY ĐỔI' : 'LƯU HÀNG HÓA',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final code = codeCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập tên hàng hóa (*)')),
                                );
                                return;
                              }
                              if (code.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập mã hàng hóa (*)')),
                                );
                                return;
                              }

                              final cost = double.tryParse(costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                              final price = double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                              final stock = double.tryParse(stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

                              final newProductModel = ProductModel(
                                id: isEdit ? product.id : null,
                                maHang: code,
                                tenHang: name,
                                maNhom: groupCtrl.text.trim(),
                                donViTinh: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'Cái',
                                giaVon: cost,
                                giaBan: price,
                                tonKho: stock,
                                chiNhanh: branchCtrl.text.trim().isNotEmpty ? branchCtrl.text.trim() : branchVm.selectedBranch.displayName,
                                coQuanLyImei: imeiManaged,
                                trangThai: status,
                              );

                              Navigator.pop(ctx);
                              bool success;
                              if (isEdit) {
                                success = await vm.editProduct(newProductModel);
                              } else {
                                success = await vm.addProduct(newProductModel);
                              }

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Đã cập nhật hàng hóa: $name' : 'Đã thêm mới hàng hóa: $name'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi ${isEdit ? "cập nhật" : "thêm"} hàng hóa, vui lòng thử lại!'),
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
      },
    );
  }
}
