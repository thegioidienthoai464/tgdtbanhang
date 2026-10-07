import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/bank_model.dart';
import '../branch/branch_view_model.dart';
import '../branch/branch_filter_chips.dart';
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
    final branchVm = context.watch<BranchViewModel>();

    final totalFund = branchVm.isAllSelected
        ? vm.totalFund
        : vm.filteredTotalFund(branchVm.matchesBranch);
    final cashBalance = branchVm.isAllSelected
        ? vm.cashBalance
        : vm.filteredCashBalance(branchVm.matchesBranch);
    final bankBalance = branchVm.isAllSelected
        ? vm.bankBalance
        : vm.filteredBankBalance(branchVm.matchesBranch);

    final filteredTransactions = vm.transactions
        .where((t) => branchVm.matchesBranch(t.chiNhanh))
        .toList();

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
        onPressed: () => _showAddTransactionModal(context, vm, branchVm),
      ),
      body: Column(
        children: [
          // Bộ chọn chi nhánh cho sổ quỹ
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: BranchFilterChips(showHeader: true, title: 'Chi nhánh sổ quỹ:'),
          ),

          // Thẻ tổng hợp quỹ tài chính toàn diện
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'TỔNG TỒN QUỸ (Tiền mặt + Ngân hàng)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.formatCurrency(totalFund),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: totalFund >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Quỹ tiền mặt
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payments_outlined, color: Colors.amber, size: 15),
                                SizedBox(width: 6),
                                Text('Quỹ tiền mặt', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(cashBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      const SizedBox(width: 12),
                      // Quỹ ngân hàng
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_outlined, color: Color(0xFF38BDF8), size: 15),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vm.selectedBankAccount != null
                                        ? vm.selectedBankAccount!.tenNH
                                        : 'Quỹ ngân hàng',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(bankBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                                fontSize: 14,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
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
                _buildFilterChip(context, 'Ngân hàng', 'TAI_KHOAN', vm),
              ],
            ),
          ),

          // Bộ chọn tài khoản ngân hàng (Hiển thị 1 tài khoản hoặc Tất cả)
          if (vm.selectedTab != 'TIEN_MAT' && vm.bankAccounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: vm.selectedBankAccount != null ? AppTheme.primaryBlue : AppTheme.borderSubtle,
                    width: vm.selectedBankAccount != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 18,
                      color: vm.selectedBankAccount != null ? AppTheme.primaryBlue : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tài khoản: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BankModel?>(
                          isExpanded: true,
                          value: vm.selectedBankAccount,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: [
                            const DropdownMenuItem<BankModel?>(
                              value: null,
                              child: Text('Tất cả tài khoản', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            ...vm.bankAccounts.map((b) {
                              return DropdownMenuItem<BankModel?>(
                                value: b,
                                child: Text(
                                  b.displayName,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (bank) {
                            vm.selectBankAccount(bank);
                          },
                        ),
                      ),
                    ),
                    if (vm.selectedBankAccount != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppTheme.textMuted),
                        tooltip: 'Xem tất cả',
                        onPressed: () => vm.selectBankAccount(null),
                      ),
                  ],
                ),
              ),
            ),

          // Danh sách giao dịch
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? const Center(child: Text('Chưa có giao dịch sổ quỹ nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final t = filteredTransactions[index];

                          final isThu = t.isIncome;
                          final isTm = t.loaiQuy.toUpperCase() == 'TIEN_MAT' ||
                                       t.loaiQuy.toUpperCase().contains('TIỀN MẶT') ||
                                       t.loaiQuy.toUpperCase().contains('TIEN MAT');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
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
                                '${t.maPhieu} • ${t.chiNhanh}\n${Formatters.formatDateTime(t.ngayGD)} • ${isTm ? "💵 Tiền mặt" : "💳 ${t.loaiQuy}"}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              isThreeLine: true,
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
      onSelected: (_) => vm.switchTab(value),
    );
  }

  void _showAddTransactionModal(BuildContext context, CashbookViewModel vm, BranchViewModel branchVm) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final partnerCtrl = TextEditingController();
    String loaiPhieu = 'THU';
    String loaiHinh = 'TIEN_MAT'; // 'TIEN_MAT' hoặc 'NGAN_HANG'
    BankModel? chosenBank = vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lập phiếu thu / chi nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Thông tin chi nhánh hạch toán
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chi nhánh hạch toán: ${branchVm.selectedBranch.displayName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chọn Loại phiếu Thu / Chi
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

                    // Chọn Quỹ: Tiền mặt hay Chuyển khoản ngân hàng
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Tiền mặt'),
                          selected: loaiHinh == 'TIEN_MAT',
                          onSelected: (_) => setModalState(() => loaiHinh = 'TIEN_MAT'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tài khoản ngân hàng'),
                          selected: loaiHinh == 'NGAN_HANG',
                          onSelected: (_) => setModalState(() => loaiHinh = 'NGAN_HANG'),
                        ),
                      ],
                    ),

                    // Dropdown chọn ngân hàng nếu là chuyển khoản
                    if (loaiHinh == 'NGAN_HANG' && vm.bankAccounts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BankModel>(
                            isExpanded: true,
                            value: chosenBank,
                            hint: const Text('Chọn tài khoản ngân hàng'),
                            items: vm.bankAccounts.map((b) {
                              return DropdownMenuItem<BankModel>(
                                value: b,
                                child: Text(b.displayName, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (b) => setModalState(() => chosenBank = b),
                          ),
                        ),
                      ),
                    ],

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

                          final finalQuy = loaiHinh == 'TIEN_MAT'
                              ? 'TIEN_MAT'
                              : (chosenBank?.displayName ?? 'TAI_KHOAN');

                          await vm.addTransaction(
                            loaiPhieu: loaiPhieu,
                            loaiQuy: finalQuy,
                            soTien: val,
                            doiTuong: partnerCtrl.text.trim(),
                            ghiChu: descCtrl.text.trim(),
                            chiNhanh: branchVm.selectedBranch.displayName,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('XÁC NHẬN GHI SỔ'),
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
