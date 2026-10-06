import 'package:flutter/material.dart';
import '../../../data/services/lan_printer_service.dart';
import '../../../data/services/update_service.dart';
import '../../core/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _storeAddrCtrl = TextEditingController();
  final _storePhoneCtrl = TextEditingController();

  bool _autoPrint = true;
  String _paperSize = '80mm';
  bool _isTestingPrinter = false;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ip = await LanPrinterService.getPrinterIp();
    final port = await LanPrinterService.getPrinterPort();
    final auto = await LanPrinterService.isAutoPrintEnabled();
    final size = await LanPrinterService.getPaperSize();

    setState(() {
      _ipCtrl.text = ip;
      _portCtrl.text = port.toString();
      _autoPrint = auto;
      _paperSize = size;
      _storeNameCtrl.text = 'THE GIOI DIEN THOAI 464';
      _storeAddrCtrl.text = '464 Le Van Khuong, P. Thoi An, Q.12';
      _storePhoneCtrl.text = '0989.xxx.xxx';
    });
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _storeNameCtrl.dispose();
    _storeAddrCtrl.dispose();
    _storePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final port = int.tryParse(_portCtrl.text.trim()) ?? 9100;
    await LanPrinterService.saveSettings(
      ip: _ipCtrl.text.trim(),
      port: port,
      autoPrint: _autoPrint,
      paperSize: _paperSize,
      storeName: _storeNameCtrl.text.trim(),
      storeAddress: _storeAddrCtrl.text.trim(),
      storePhone: _storePhoneCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu cấu hình máy in và cửa hàng thành công!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  Future<void> _testPrinter() async {
    setState(() => _isTestingPrinter = true);
    final port = int.tryParse(_portCtrl.text.trim()) ?? 9100;
    final res = await LanPrinterService.testPrint(
      ip: _ipCtrl.text.trim(),
      port: port,
    );
    setState(() => _isTestingPrinter = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? AppTheme.successGreen : AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _manualCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    final update = await UpdateService.checkForUpdate();
    setState(() => _isCheckingUpdate = false);

    if (!mounted) return;

    if (update != null) {
      UpdateService.showUpdateDialog(context, update, isManualCheck: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Bạn đang sử dụng phiên bản mới nhất (v1.0.1)!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mục Máy in LAN
          _buildCard(
            title: 'MÁY IN HÓA ĐƠN MẠNG LAN (WIFI)',
            icon: Icons.print_rounded,
            children: [
              TextField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ IP máy in LAN',
                  hintText: 'Ví dụ: 192.168.1.200',
                  prefixIcon: Icon(Icons.router_outlined),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cổng Port (Mặc định 9100)',
                  hintText: '9100',
                  prefixIcon: Icon(Icons.settings_ethernet_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Khổ giấy in: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Khổ 80mm (K80)'),
                    selected: _paperSize == '80mm',
                    onSelected: (val) {
                      if (val) setState(() => _paperSize = '80mm');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Khổ 58mm (K58)'),
                    selected: _paperSize == '58mm',
                    onSelected: (val) {
                      if (val) setState(() => _paperSize = '58mm');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tự động in bill sau khi thanh toán'),
                subtitle: const Text('Gửi lệnh in tức thì khi nhân viên bấm hoàn tất đơn POS', style: TextStyle(fontSize: 12)),
                value: _autoPrint,
                onChanged: (val) => setState(() => _autoPrint = val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isTestingPrinter 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.print_outlined),
                      label: const Text('In thử nghiệm'),
                      onPressed: _isTestingPrinter ? null : _testPrinter,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Lưu máy in'),
                      onPressed: _saveSettings,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mục Thông tin cửa hàng trên Bill
          _buildCard(
            title: 'THÔNG TIN CỬA HÀNG TRÊN HÓA ĐƠN',
            icon: Icons.storefront_outlined,
            children: [
              TextField(
                controller: _storeNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _storeAddrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ in trên bill',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _storePhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại / Hotline',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mục Cập nhật phần mềm
          _buildCard(
            title: 'CẬP NHẬT PHẦN MỀM (AUTO UPDATE)',
            icon: Icons.system_update_alt_rounded,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phiên bản hiện tại:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'v1.0.2 (Build 3)',
                      style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Ứng dụng tự động kiểm tra bản cập nhật mới nhất từ máy chủ khi khởi động. Bạn cũng có thể bấm nút kiểm tra thủ công bên dưới.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isCheckingUpdate
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Kiểm tra bản cập nhật mới'),
                  onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
