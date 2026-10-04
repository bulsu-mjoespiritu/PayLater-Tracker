import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'add_bill_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _monthFmt = DateFormat('MMM');
final _dateFmt = DateFormat('MMM dd, yyyy');

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBillScreen()),
              ),
              child: const Text('+ New Bill'),
            ),
          ),
        ],
      ),
      body: bills.isEmpty
          ? const Center(
              child: Text('No bills added yet', style: TextStyle(color: AppColors.textMuted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: bills.length,
              itemBuilder: (context, index) => _BillGroupCard(bill: bills[index]),
            ),
    );
  }
}

class _BillGroupCard extends StatelessWidget {
  final Bill bill;
  const _BillGroupCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: AppColors.lightOrangeBg, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Total Bill: ${_currency.format(bill.totalBill)}  •  ${bill.installmentMonths} months',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge.forLabel(bill.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 4),
          ...bill.installments.map((inst) => _InstallmentRow(bill: bill, inst: inst)),
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
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
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
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(width: 6),
              Text(
                '(Month ${inst.monthIndex} of ${bill.installmentMonths})',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              StatusBadge.forLabel(inst.displayLabel),
              const SizedBox(width: 2),
              IconButton(
                onPressed: () => _editSaved(context),
                icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.textMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                tooltip: 'Edit saved amount',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Due: ${_dateFmt.format(inst.dueDate)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Saved: ${_currency.format(inst.saved)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, fontWeight: FontWeight.w600)),
              ),
              Text(
                'Remaining: ${_currency.format(inst.remaining(bill.monthlyPayment))}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.red, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.lightGreyBg,
              valueColor: AlwaysStoppedAnimation(
                inst.status == InstallmentStatus.paid ? AppColors.green : AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
