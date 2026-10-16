import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../../data/models/bank_model.dart';
import '../../../data/models/cashbook_model.dart';
import '../../../data/services/lan_printer_service.dart';
import '../branch/branch_view_model.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sổ quỹ thu chi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              'Chi nhánh: ${branchVm.summaryDisplayName}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
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
            tooltip: 'Làm mới',
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
          // Thẻ tổng hợp quỹ tài chính gọn gàng, tối ưu không gian hiển thị
          Container(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cột trái: Tổng tồn quỹ
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'TỔNG TỒN QUỸ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Formatters.formatCurrency(totalFund),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: totalFund >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Cột phải: Tiền mặt & Ngân hàng
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          const Text('TM: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Formatters.formatCurrency(cashBalance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined, color: Color(0xFF38BDF8), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            vm.selectedBankAccount != null
                                ? '${vm.selectedBankAccount!.tenNH.split(" ").first}: '
                                : 'NH: ',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Formatters.formatCurrency(bankBalance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thanh lọc quỹ gọn nhẹ gom chung 1 dòng: [Tất cả] [Tiền mặt] [Ngân hàng] và [Chọn TK NH ▾]
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
            child: Row(
              children: [
                _buildCompactFilterChip('Tất cả', 'ALL', vm),
                const SizedBox(width: 6),
                _buildCompactFilterChip('Tiền mặt', 'TIEN_MAT', vm),
                const SizedBox(width: 6),
                _buildCompactFilterChip('Ngân hàng', 'TAI_KHOAN', vm),
                const Spacer(),
                if (vm.selectedTab != 'TIEN_MAT' && vm.bankAccounts.isNotEmpty)
                  _buildCompactBankSelector(context, vm),
              ],
            ),
          ),

          // Danh sách giao dịch
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? const Center(child: Text('Chưa có giao dịch sổ quỹ nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          final t = filteredTransactions[index];

                          final isThu = t.isIncome;
                          final isTm = t.loaiQuy.toUpperCase() == 'TIEN_MAT' ||
                                       t.loaiQuy.toUpperCase().contains('TIỀN MẶT') ||
                                       t.loaiQuy.toUpperCase().contains('TIEN MAT');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: InkWell(
                              onTap: () => _showTransactionDetailModal(context, t, vm, branchVm),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isThu ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isThu ? Icons.arrow_downward : Icons.arrow_upward,
                                        size: 16,
                                        color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            t.ghiChu.isNotEmpty ? t.ghiChu : (isThu ? 'Thu tiền' : 'Chi tiền'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${t.maPhieu} • ${Formatters.formatDateTime(t.ngayGD)}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${isTm ? "💵 Tiền mặt" : "💳 ${t.loaiQuy}"}${t.chiNhanh.isNotEmpty ? " • ${t.chiNhanh}" : ""}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isTm ? Colors.amber.shade800 : const Color(0xFF0284C7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${isThu ? '+' : '-'}${Formatters.formatCurrency(t.soTien)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Icon(Icons.chevron_right, size: 14, color: AppTheme.textMuted),
                                      ],
                                    ),
                                  ],
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

  Widget _buildCompactFilterChip(String label, String value, CashbookViewModel vm) {
    final isSelected = vm.selectedTab == value;
    return InkWell(
      onTap: () => vm.switchTab(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBankSelector(BuildContext context, CashbookViewModel vm) {
    final currentBank = vm.selectedBankAccount;
    return PopupMenuButton<BankModel?>(
      initialValue: currentBank,
      tooltip: 'Lọc tài khoản ngân hàng',
      onSelected: (bank) => vm.selectBankAccount(bank),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        const PopupMenuItem<BankModel?>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.all_inclusive, size: 16, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Tất cả tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...vm.bankAccounts.map((b) => PopupMenuItem<BankModel?>(
          value: b,
          child: Row(
            children: [
              const Icon(Icons.account_balance, size: 16, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(
                child: Text(b.displayName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: currentBank != null ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: currentBank != null ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance,
              size: 13,
              color: currentBank != null ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 85),
              child: Text(
                currentBank != null ? currentBank.tenNH : 'Tất cả TK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: currentBank != null ? AppTheme.primaryBlue : AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, CashbookViewModel vm, BranchViewModel branchVm) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final partnerCtrl = TextEditingController();
    String loaiPhieu = 'THU';
    String loaiHinh = 'TIEN_MAT'; // 'TIEN_MAT' hoặc 'NGAN_HANG'
    BankModel? chosenBank = vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null;
    String selectedCategory = 'Chuyển/ rút';

    // Biến cho nghiệp vụ Chuyển / Rút
    String fromQuyType = 'TIEN_MAT';
    BankModel? fromBank = vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : null;
    String toQuyType = 'NGAN_HANG';
    BankModel? toBank = vm.bankAccounts.isNotEmpty ? (vm.bankAccounts.length > 1 ? vm.bankAccounts[1] : vm.bankAccounts.first) : null;
    bool autoPairTransfer = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isChuyenRut = selectedCategory == 'Chuyển/ rút';
            final categories = loaiPhieu == 'THU' ? vm.incomeCategories : vm.expenseCategories;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isChuyenRut ? 'Chuyển / Rút Tiền Nội Bộ' : 'Lập phiếu thu / chi nhanh',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

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

                    // 1. Chọn Hạng mục thu / chi mẫu (Có Chuyển/ rút và Thêm mẫu mới)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hạng mục mẫu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          label: const Text('Thêm mẫu', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final newName = await showDialog<String>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Thêm hạng mục mẫu mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                content: TextField(
                                  controller: nameCtrl,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Tên hạng mục (*)',
                                    hintText: 'VD: Chi tiếp khách VIP, Thu hoàn ứng...',
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Hủy')),
                                  ElevatedButton(
                                    onPressed: () {
                                      final t = nameCtrl.text.trim();
                                      if (t.isNotEmpty) Navigator.pop(dCtx, t);
                                    },
                                    child: const Text('Thêm'),
                                  ),
                                ],
                              ),
                            );

                            if (newName != null && newName.isNotEmpty) {
                              vm.addCustomCategory(newName, isIncome: loaiPhieu == 'THU');
                              setModalState(() => selectedCategory = newName);
                            }
                          },
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: categories.contains(selectedCategory) ? selectedCategory : categories.first,
                          items: categories.map((c) {
                            final isCR = c == 'Chuyển/ rút';
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                isCR ? '🔄 Chuyển/ rút (Tiền mặt ⇄ Ngân hàng)' : c,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCR ? FontWeight.bold : FontWeight.normal,
                                  color: isCR ? AppTheme.primaryBlue : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedCategory = val;
                                if (val == 'Chuyển/ rút' && partnerCtrl.text.isEmpty) {
                                  partnerCtrl.text = 'Nội bộ';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // NẾU LÀ "CHUYỂN/ RÚT": HIỂN THỊ KHỐI CHUYỂN RÚT GIỮA CÁC QUỸ
                    if (isChuyenRut) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.sync_alt, size: 16, color: Color(0xFF4F46E5)),
                                SizedBox(width: 6),
                                Text(
                                  'ĐIỀU CHUYỂN QUỸ NỘI BỘ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3730A3)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // TỪ QUỸ
                            Row(
                              children: [
                                const Text('Từ quỹ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent)),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Tiền mặt', style: TextStyle(fontSize: 11)),
                                  selected: fromQuyType == 'TIEN_MAT',
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setModalState(() => fromQuyType = 'TIEN_MAT'),
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  label: const Text('Ngân hàng', style: TextStyle(fontSize: 11)),
                                  selected: fromQuyType == 'NGAN_HANG',
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setModalState(() => fromQuyType = 'NGAN_HANG'),
                                ),
                              ],
                            ),
                            if (fromQuyType == 'NGAN_HANG' && vm.bankAccounts.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BankModel>(
                                    isExpanded: true,
                                    value: fromBank ?? vm.bankAccounts.first,
                                    items: vm.bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b.displayName, style: const TextStyle(fontSize: 11.5)))).toList(),
                                    onChanged: (b) => setModalState(() => fromBank = b),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // ĐẾN QUỸ
                            Row(
                              children: [
                                const Text('Đến quỹ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.successGreen)),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Ngân hàng', style: TextStyle(fontSize: 11)),
                                  selected: toQuyType == 'NGAN_HANG',
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setModalState(() => toQuyType = 'NGAN_HANG'),
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  label: const Text('Tiền mặt', style: TextStyle(fontSize: 11)),
                                  selected: toQuyType == 'TIEN_MAT',
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) => setModalState(() => toQuyType = 'TIEN_MAT'),
                                ),
                              ],
                            ),
                            if (toQuyType == 'NGAN_HANG' && vm.bankAccounts.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BankModel>(
                                    isExpanded: true,
                                    value: toBank ?? (vm.bankAccounts.length > 1 ? vm.bankAccounts[1] : vm.bankAccounts.first),
                                    items: vm.bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b.displayName, style: const TextStyle(fontSize: 11.5)))).toList(),
                                    onChanged: (b) => setModalState(() => toBank = b),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: autoPairTransfer,
                                    onChanged: (v) => setModalState(() => autoPairTransfer = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text('Tự động tạo cặp phiếu đối ứng (Chi nguồn & Thu đích)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      // NẾU KHÔNG PHẢI CHUYỂN RÚT: CHỌN LOẠI PHIẾU VÀ NGUỒN QUỸ BÌNH THƯỜNG
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
                      const SizedBox(height: 10),

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
                    ],

                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (VNĐ) (*)',
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
                        labelText: 'Ghi chú thêm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isChuyenRut ? const Color(0xFF4F46E5) : (loaiPhieu == 'THU' ? AppTheme.successGreen : AppTheme.dangerRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final val = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                          if (val <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập số tiền lớn hơn 0!')),
                            );
                            return;
                          }

                          if (isChuyenRut && autoPairTransfer) {
                            final fromQ = fromQuyType == 'TIEN_MAT' ? 'TIEN_MAT' : (fromBank?.displayName ?? 'TAI_KHOAN');
                            final toQ = toQuyType == 'TIEN_MAT' ? 'TIEN_MAT' : (toBank?.displayName ?? 'TAI_KHOAN');

                            if (fromQ == toQ) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Quỹ nguồn và Quỹ đích không được trùng nhau!')),
                              );
                              return;
                            }

                            await vm.transferFunds(
                              fromQuy: fromQ,
                              toQuy: toQ,
                              soTien: val,
                              doiTuong: partnerCtrl.text.trim(),
                              ghiChu: descCtrl.text.trim(),
                              chiNhanh: branchVm.selectedBranch.displayName,
                            );
                          } else {
                            final finalQuy = loaiHinh == 'TIEN_MAT'
                                ? 'TIEN_MAT'
                                : (chosenBank?.displayName ?? 'TAI_KHOAN');

                            final note = selectedCategory.isNotEmpty
                                ? '[$selectedCategory] ${descCtrl.text.trim()}'
                                : descCtrl.text.trim();

                            await vm.addTransaction(
                              loaiPhieu: loaiPhieu,
                              loaiQuy: finalQuy,
                              soTien: val,
                              doiTuong: partnerCtrl.text.trim(),
                              ghiChu: note,
                              chiNhanh: branchVm.selectedBranch.displayName,
                            );
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                          isChuyenRut ? 'XÁC NHẬN CHUYỂN / RÚT TIỀN' : 'XÁC NHẬN GHI SỔ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
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

  // Modal Chi tiết phiếu thu / chi với 4 hành động: In, Chia sẻ, Sửa phiếu, Hủy phiếu
  void _showTransactionDetailModal(
    BuildContext context,
    CashbookModel tx,
    CashbookViewModel vm,
    BranchViewModel branchVm,
  ) {
    final isThu = tx.isIncome;
    final isTm = tx.loaiQuy.toUpperCase() == 'TIEN_MAT' ||
                 tx.loaiQuy.toUpperCase().contains('TIỀN MẶT') ||
                 tx.loaiQuy.toUpperCase().contains('TIEN MAT');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isThu ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.dangerRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isThu ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isThu ? 'PHIẾU THU TIỀN' : 'PHIẾU CHI TIỀN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tx.maPhieu,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chi nhánh: ${tx.chiNhanh} • Trạng thái: Đã hoàn tất',
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
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
                const Divider(height: 20),

                // 2. Thẻ số tiền nổi bật
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isThu ? AppTheme.successGreen.withOpacity(0.08) : AppTheme.dangerRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isThu ? AppTheme.successGreen.withOpacity(0.25) : AppTheme.dangerRed.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isThu ? 'SỐ TIỀN THU VÀO' : 'SỐ TIỀN CHI RA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${isThu ? '+' : '-'}${Formatters.formatCurrency(tx.soTien)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isThu ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Bảng chi tiết thông tin phiếu
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.calendar_today_outlined, 'Ngày giờ giao dịch', Formatters.formatDateTime(tx.ngayGD)),
                      const Divider(height: 16),
                      _buildDetailRow(Icons.account_balance_wallet_outlined, 'Loại quỹ hạch toán', isTm ? '💵 Tiền mặt' : '💳 ${tx.loaiQuy}'),
                      const Divider(height: 16),
                      _buildDetailRow(Icons.person_outline, isThu ? 'Người nộp tiền' : 'Người nhận tiền', tx.doiTuong.isNotEmpty ? tx.doiTuong : 'Chưa nhập tên'),
                      if (tx.maChungTu.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildDetailRow(Icons.receipt_outlined, 'Mã chứng từ gốc', tx.maChungTu),
                      ],
                      const Divider(height: 16),
                      _buildDetailRow(Icons.note_alt_outlined, 'Lý do & ghi chú', tx.ghiChu.isNotEmpty ? tx.ghiChu : 'Không có ghi chú'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Bốn hành động chính: In, Chia sẻ, Sửa phiếu, Hủy phiếu
                const Text('Thao tác với phiếu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),

                // Hàng 1: In phiếu & Chia sẻ
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppTheme.primaryBlue),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.primaryBlue),
                        label: const Text('In phiếu LAN', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final res = await LanPrinterService.printCashReceipt(tx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? ''),
                                backgroundColor: res['success'] == true ? AppTheme.successGreen : AppTheme.dangerRed,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.blue.shade700),
                        ),
                        icon: Icon(Icons.share_outlined, size: 18, color: Colors.blue.shade700),
                        label: Text('Chia sẻ phiếu', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final text = """
══════════════════════════════
THẾ GIỚI ĐIỆN THOẠI 464
${isThu ? "PHIẾU THU TIỀN" : "PHIẾU CHI TIỀN"} - ${tx.maPhieu}
══════════════════════════════
• Chi nhánh : ${tx.chiNhanh}
• Thời gian : ${Formatters.formatDateTime(tx.ngayGD)}
• Người ${isThu ? "nộp" : "nhận"}: ${tx.doiTuong.isNotEmpty ? tx.doiTuong : "Khách hàng"}
• Loại quỹ  : ${isTm ? "Tiền mặt" : tx.loaiQuy}
• Số tiền   : ${Formatters.formatCurrency(tx.soTien)}
• Lý do     : ${tx.ghiChu.isNotEmpty ? tx.ghiChu : "Không có"}
${tx.maChungTu.isNotEmpty ? "• Chứng từ  : ${tx.maChungTu}\n" : ""}══════════════════════════════
                          """.trim();

                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (sCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
                                    SizedBox(width: 8),
                                    Text('Nội dung phiếu đã sao chép', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                                content: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    text,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(sCtx), child: const Text('ĐÓNG')),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Đã copy (Gửi Zalo/SMS)'),
                                    onPressed: () => Navigator.pop(sCtx),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hàng 2: Sửa phiếu & Hủy phiếu
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: const Text('Sửa phiếu', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditTransactionModal(context, tx, vm, branchVm);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.dangerRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hủy phiếu', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Xác nhận hủy phiếu?'),
                              content: Text(
                                'Bạn có chắc chắn muốn hủy phiếu "${tx.maPhieu}" với số tiền ${Formatters.formatCurrency(tx.soTien)}?\n\n'
                                'Hành động này sẽ xóa phiếu khỏi sổ quỹ và số dư quỹ sẽ được tính toán lại.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('KHÔNG')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    Navigator.pop(c);
                                    Navigator.pop(ctx);
                                    final ok = await vm.cancelTransaction(tx.maPhieu);
                                    if (ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã hủy phiếu ${tx.maPhieu} thành công!'),
                                          backgroundColor: AppTheme.dangerRed,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('XÁC NHẬN HỦY'),
                                ),
                              ],
                            ),
                          );
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Modal Sửa phiếu thu / chi
  void _showEditTransactionModal(
    BuildContext context,
    CashbookModel tx,
    CashbookViewModel vm,
    BranchViewModel branchVm,
  ) {
    final amountCtrl = TextEditingController(text: Formatters.formatNumber(tx.soTien));
    final descCtrl = TextEditingController(text: tx.ghiChu);
    final partnerCtrl = TextEditingController(text: tx.doiTuong);
    String loaiPhieu = tx.loaiPhieu;
    bool isTm = tx.loaiQuy.toUpperCase() == 'TIEN_MAT' ||
                tx.loaiQuy.toUpperCase().contains('TIỀN MẶT') ||
                tx.loaiQuy.toUpperCase().contains('TIEN MAT');
    String loaiHinh = isTm ? 'TIEN_MAT' : 'NGAN_HANG';

    BankModel? chosenBank = vm.bankAccounts.firstWhere(
      (b) => tx.loaiQuy.toUpperCase().contains(b.tenNH.toUpperCase()) || tx.loaiQuy.toUpperCase().contains(b.soTK.toUpperCase()),
      orElse: () => vm.bankAccounts.isNotEmpty ? vm.bankAccounts.first : BankModel(maNH: 'NH', tenNH: tx.loaiQuy, soTK: ''),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chỉnh sửa phiếu: ${tx.maPhieu}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),

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

                    // Chọn Quỹ: Tiền mặt hay Ngân hàng
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
                      inputFormatters: [CurrencyInputFormatter()],
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final val = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                          if (val <= 0) return;

                          final finalQuy = loaiHinh == 'TIEN_MAT'
                              ? 'TIEN_MAT'
                              : (chosenBank?.displayName ?? 'TAI_KHOAN');

                          final updatedTx = CashbookModel(
                            maPhieu: tx.maPhieu,
                            chiNhanh: tx.chiNhanh,
                            loaiPhieu: loaiPhieu,
                            loaiQuy: finalQuy,
                            ngayGD: tx.ngayGD,
                            soTien: val,
                            doiTuong: partnerCtrl.text.trim(),
                            maDoiTuong: tx.maDoiTuong,
                            maChungTu: tx.maChungTu,
                            trangThai: tx.trangThai,
                            ghiChu: descCtrl.text.trim(),
                          );

                          Navigator.pop(ctx);
                          final ok = await vm.editTransaction(updatedTx);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã cập nhật phiếu ${tx.maPhieu} thành công!'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        },
                        child: const Text('LƯU THAY ĐỔI PHIẾU', style: TextStyle(fontWeight: FontWeight.bold)),
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
