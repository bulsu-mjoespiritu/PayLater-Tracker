import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _monthFmt = DateFormat('MMM');
final _dateFmt = DateFormat('MMM dd, yyyy');

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  /// Ids of bills the user has minimized. Everything starts expanded.
  final Set<String> _collapsed = {};

  void _toggle(String billId) {
    setState(() {
      if (!_collapsed.remove(billId)) _collapsed.add(billId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: NewBillButton(),
          ),
        ],
      ),
      body: bills.isEmpty
          ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No bills added yet')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return _BillGroupCard(
                  key: ValueKey(bill.id),
                  bill: bill,
                  expanded: !_collapsed.contains(bill.id),
                  onToggle: () => _toggle(bill.id),
                );
              },
            ),
    );
  }
}

class _BillGroupCard extends StatelessWidget {
  final Bill bill;
  final bool expanded;
  final VoidCallback onToggle;

  const _BillGroupCard({
    super.key,
    required this.bill,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tap the header to minimize / expand the bill.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconBadge(icon: Icons.shopping_bag_outlined, color: p.orange, background: p.orangeBg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bill.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                        const SizedBox(height: 2),
                        Text(
                          'Total Bill: ${_currency.format(bill.totalBill)}  •  ${bill.installmentMonths} months',
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                        if (!expanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${bill.paidCount} of ${bill.installmentMonths} paid',
                            style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge.forLabel(bill.statusLabel),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        ...bill.installments.map((inst) => _InstallmentRow(bill: bill, inst: inst)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  final Bill bill;
  final Installment inst;
  const _InstallmentRow({required this.bill, required this.inst});

  Future<void> _editSaved(BuildContext context) async {
    final p = context.pal;
    final controller = TextEditingController(text: _trimZeros(inst.saved));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Month ${inst.monthIndex} Saved Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use this to fix a mistake — like accidentally tapping "+ Add" '
              'and marking this month paid too early.',
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saved amount ₱', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      context.read<BillProvider>().setInstallmentSaved(bill.id, inst.monthIndex, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Month ${inst.monthIndex} updated to ${_currency.format(result)} saved')),
      );
    }
  }

  String _trimZeros(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final progress = inst.progress(bill.monthlyPayment);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _monthFmt.format(inst.dueDate),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text),
              ),
              const SizedBox(width: 6),
              Text(
                '(Month ${inst.monthIndex} of ${bill.installmentMonths})',
                style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              StatusBadge.forLabel(inst.displayLabel),
              const SizedBox(width: 4),
              CardIconButton(
                icon: Icons.edit_outlined,
                color: p.textMuted,
                tooltip: 'Edit saved amount',
                onPressed: () => _editSaved(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Due: ${_dateFmt.format(inst.dueDate)}', style: TextStyle(fontSize: 12.5, color: p.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Saved: ${_currency.format(inst.saved)}',
                    style: TextStyle(fontSize: 12.5, color: p.text, fontWeight: FontWeight.w600)),
              ),
              Text(
                'Remaining: ${_currency.format(inst.remaining(bill.monthlyPayment))}',
                style: TextStyle(fontSize: 12.5, color: p.red, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: p.greyBg,
              valueColor: AlwaysStoppedAnimation(
                inst.status == InstallmentStatus.paid ? p.green : p.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
