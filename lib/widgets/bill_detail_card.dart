import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../screens/add_bill_screen.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _monthFmt = DateFormat('MMM');
final _fullDateFmt = DateFormat('MMMM dd, yyyy');

/// Detailed, interactive card shown on the Home screen for a bill's
/// currently-active installment. Lets the user type in a saving amount
/// and tap "+ Add" to apply it.
class BillDetailCard extends StatefulWidget {
  final Bill bill;

  const BillDetailCard({super.key, required this.bill});

  @override
  State<BillDetailCard> createState() => _BillDetailCardState();
}

class _BillDetailCardState extends State<BillDetailCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return;

    final provider = context.read<BillProvider>();
    provider.addSaving(widget.bill.id, amount);
    _controller.clear();
    FocusScope.of(context).unfocus();

    // If that payment finished the bill, it just got auto-archived to
    // History — check there for any leftover excess to let the user know.
    final stillActive = provider.bills.any((b) => b.id == widget.bill.id);
    if (!stillActive) {
      Bill? archived;
      for (final b in provider.history) {
        if (b.id == widget.bill.id) {
          archived = b;
          break;
        }
      }
      if (archived != null && archived.excessCredit > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 "${widget.bill.name}" fully paid! You have ${_currency.format(archived.excessCredit)} left over.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _withdraw(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return;

    final current = widget.bill.currentInstallment;
    if (current == null) return;

    if (amount > current.saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You only have ${_currency.format(current.saved)} saved for this month.')),
      );
      return;
    }

    context.read<BillProvider>().withdrawSaving(widget.bill.id, amount);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  void _editBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBillScreen(billToEdit: widget.bill)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text(
          '"${widget.bill.name}" will be moved to History. This won\'t affect other bills.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<BillProvider>().deleteBill(widget.bill.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.bill.name}" moved to History')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    if (bill.isCompleted) {
      return _CompletedCard(bill: bill);
    }

    final inst = bill.currentInstallment!;
    final progress = inst.progress(bill.monthlyPayment);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _monthFmt.format(inst.dueDate),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(width: 6),
              Text(
                '(Month ${inst.monthIndex} of ${bill.installmentMonths})',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              StatusBadge.forLabel(inst.displayLabel),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _editBill(context),
                icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.textMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Edit bill',
              ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.red),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Delete bill',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bill.name,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          // Big monthly amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currency.format(bill.monthlyPayment),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(width: 8),
              const Text('monthly', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_fullDateFmt.format(inst.dueDate)} Due  •  Month ${inst.monthIndex}/${bill.installmentMonths}',
            style: TextStyle(
              fontSize: 12.5,
              color: inst.isOverdue ? AppColors.red : AppColors.textMuted,
              fontWeight: inst.isOverdue ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          // Saved / Remaining row
          Row(
            children: [
              Expanded(
                child: _LabelValue(
                  label: 'Saved',
                  value: _currency.format(inst.saved),
                  valueColor: AppColors.green,
                ),
              ),
              Expanded(
                child: _LabelValue(
                  label: 'Remaining',
                  value: _currency.format(inst.remaining(bill.monthlyPayment)),
                  valueColor: AppColors.red,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.lightGreyBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          // Amount input, shared by both "Add" and "Withdraw"
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Amount ₱',
              isDense: true,
            ),
            onSubmitted: (_) => _submit(context),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _withdraw(context),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.red),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('+ Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _LabelValue({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final Bill bill;
  const _CompletedCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.lightGreenBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'All ${bill.installmentMonths} months paid • ${_currency.format(bill.totalBill)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          StatusBadge.forLabel('Completed'),
        ],
      ),
    );
  }
}
