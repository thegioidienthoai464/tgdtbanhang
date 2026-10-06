import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/supabase_service.dart';
import 'ui/core/app_theme.dart';
import 'ui/features/branch/branch_view_model.dart';
import 'ui/features/dashboard/dashboard_view.dart';
import 'ui/features/pos/pos_view.dart';
import 'ui/features/pos/pos_view_model.dart';
import 'ui/features/orders/orders_view.dart';
import 'ui/features/orders/orders_view_model.dart';
import 'ui/features/inventory/inventory_view.dart';
import 'ui/features/inventory/inventory_view_model.dart';
import 'ui/features/cashbook/cashbook_view.dart';
import 'ui/features/cashbook/cashbook_view_model.dart';
import 'data/services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo kết nối Supabase Cloud trực tiếp
  await SupabaseService.initialize();

  runApp(const SmartErpMobileApp());
}

class SmartErpMobileApp extends StatelessWidget {
  const SmartErpMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BranchViewModel()..init()),
        ChangeNotifierProvider(create: (_) => PosViewModel()),
        ChangeNotifierProvider(create: (_) => OrdersViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => CashbookViewModel()),
      ],
      child: MaterialApp(
        title: 'T&T POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isCheckingUpdate = false;
  Timer? _periodicUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
    // Định kỳ tự động kiểm tra bản cập nhật mới mỗi 5 phút khi đang mở app
    _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkUpdate());
  }

  @override
  void dispose() {
    _periodicUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUpdate();
    }
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;
    try {
      final update = await UpdateService.checkForUpdate();
      if (mounted && update != null) {
        UpdateService.showUpdateDialog(context, update);
      }
    } finally {
      _isCheckingUpdate = false;
    }
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardView(onTabChange: _onTabChange),
      const PosView(),
      const OrdersView(),
      const InventoryView(),
      const CashbookView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChange,
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppTheme.primaryBlue.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryBlue),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: AppTheme.primaryBlue),
            label: 'Bán hàng POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppTheme.primaryBlue),
            label: 'Kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primaryBlue),
            label: 'Sổ quỹ',
          ),
        ],
      ),
    );
  }
}
