import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/bill_detail_card.dart';
import 'add_bill_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddBillScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final p = context.pal;
    final savedMoney = provider.totalSavedMoney;
    final activeCount = provider.activeBillsCount;
    final isDark = p.isDark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            const Text('PayLater Tracker'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 24),
            onPressed: () => context
                .read<ThemeController>()
                .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Saved money card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'SAVED MONEY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.savings_outlined, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currency.format(savedMoney),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'set aside for $activeCount active bill${activeCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Upcoming bills header + add
          Row(
            children: [
              Text(
                'Upcoming Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
              ),
              const Spacer(),
              const NewBillButton(),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No bills yet',
                action: ElevatedButton(
                  onPressed: () => _openAddBill(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Add your first bill'),
                  ),
                ),
              ),
            )
          else
            ...provider.bills.map((bill) => BillDetailCard(key: ValueKey(bill.id), bill: bill)),
        ],
      ),
    );
  }
}
