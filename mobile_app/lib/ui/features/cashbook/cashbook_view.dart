import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import 'cashbook_view_model.dart';

class CashbookView extends StatefulWidget {
  const CashbookView({super.key});

  @override
  State<CashbookView> createState() => _CashbookViewState();
}

class _CashbookViewState extends State<CashbookView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashbookViewModel>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CashbookViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ quỹ thu chi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.fetchTransactions(vm.selectedTab),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Lập phiếu'),
        onPressed: () => _showAddTransactionModal(context, vm),
      ),
      body: Column(
        children: [
          // Thẻ tổng hợp thu chi
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tồn quỹ thực tế', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    Text(
                      Formatters.formatCurrency(vm.balance),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: vm.balance >= 0 ? AppTheme.primaryBlue : AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward, color: AppTheme.successGreen, size: 16),
                              SizedBox(width: 4),
                              Text('Tổng thu', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(vm.totalIncome),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: AppTheme.dangerRed, size: 16),
                              SizedBox(width: 4),
                              Text('Tổng chi', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(vm.totalExpense),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lọc theo loại quỹ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(context, 'Tất cả', 'ALL', vm),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Tiền mặt', 'TIEN_MAT', vm),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Tài khoản', 'TAI_KHOAN', vm),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách giao dịch
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.transactions.isEmpty
                    ? const Center(child: Text('Chưa có giao dịch sổ quỹ nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: vm.transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final t = vm.transactions[index];
                          final isThu = t.isIncome;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isThu ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
                                child: Icon(
                                  isThu ? Icons.add : Icons.remove,
                                  color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                                ),
                              ),
                              title: Text(
                                t.ghiChu.isNotEmpty ? t.ghiChu : (isThu ? 'Thu tiền' : 'Chi tiền'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${t.maPhieu} • ${Formatters.formatDateTime(t.ngayGD)} • ${t.loaiQuy == 'TIEN_MAT' ? 'Tiền mặt' : 'Ngân hàng'}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              trailing: Text(
                                '${isThu ? '+' : '-'}${Formatters.formatCurrency(t.soTien)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, CashbookViewModel vm) {
    final isSelected = vm.selectedTab == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => vm.fetchTransactions(value),
    );
  }

  void _showAddTransactionModal(BuildContext context, CashbookViewModel vm) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final partnerCtrl = TextEditingController();
    String loaiPhieu = 'THU';
    String loaiQuy = 'TIEN_MAT';

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
                  const Text('Lập phiếu thu / chi nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Phiếu Thu (+)'),
                        selected: loaiPhieu == 'THU',
                        selectedColor: AppTheme.successGreen.withOpacity(0.2),
                        onSelected: (_) => setModalState(() => loaiPhieu = 'THU'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Phiếu Chi (-)'),
                        selected: loaiPhieu == 'CHI',
                        selectedColor: AppTheme.dangerRed.withOpacity(0.2),
                        onSelected: (_) => setModalState(() => loaiPhieu = 'CHI'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: partnerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Người nộp / nhận tiền',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lý do thu / chi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final val = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                        if (val <= 0) return;
                        await vm.addTransaction(
                          loaiPhieu: loaiPhieu,
                          loaiQuy: loaiQuy,
                          soTien: val,
                          doiTuong: partnerCtrl.text.trim(),
                          ghiChu: descCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('XÁC NHẬN GHI SỔ'),
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
