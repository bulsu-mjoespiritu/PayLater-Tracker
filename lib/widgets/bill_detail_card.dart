import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../screens/add_bill_screen.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';
import 'status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _monthFmt = DateFormat('MMM');
final _fullDateFmt = DateFormat('MMMM dd, yyyy');

/// Detailed, interactive card shown on the Home screen for a bill's
/// currently-active installment. Lets the user type in a saving amount
/// and tap "+ Add", or tap "Mark as Paid" to cover whatever is left.
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

  /// One tap to pay the month: adds exactly what's still missing, so the
  /// amount never has to be typed in.
  Future<void> _markPaid(BuildContext context) async {
    final bill = widget.bill;
    final current = bill.currentInstallment;
    if (current == null) return;

    final p = context.pal;
    final remaining = current.remaining(bill.monthlyPayment);
    final monthIndex = current.monthIndex;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BillProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as paid?'),
        content: Text(
          remaining > 0
              ? 'Month $monthIndex of "${bill.name}" will be marked as paid. '
                  '${_currency.format(remaining)} will be added to cover what\'s left.'
              : 'Month $monthIndex of "${bill.name}" will be marked as paid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.green),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    provider.markCurrentAsPaid(bill.id);
    _controller.clear();
    messenger.showSnackBar(
      SnackBar(content: Text('Month $monthIndex of "${bill.name}" marked as paid')),
    );
  }

  void _editBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBillScreen(billToEdit: widget.bill)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final p = context.pal;
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
            style: TextButton.styleFrom(foregroundColor: p.red),
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
    final p = context.pal;

    if (bill.isCompleted) {
      return _CompletedCard(bill: bill);
    }

    final inst = bill.currentInstallment!;
    final progress = inst.progress(bill.monthlyPayment);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _monthFmt.format(inst.dueDate),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(width: 6),
              Text(
                '(Month ${inst.monthIndex} of ${bill.installmentMonths})',
                style: TextStyle(fontSize: 13, color: p.textMuted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              StatusBadge.forLabel(inst.displayLabel),
              const SizedBox(width: 4),
              CardIconButton(
                icon: Icons.edit_outlined,
                color: p.textMuted,
                tooltip: 'Edit bill',
                onPressed: () => _editBill(context),
              ),
              CardIconButton(
                icon: Icons.delete_outline,
                color: p.red,
                tooltip: 'Delete bill',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bill.name,
            style: TextStyle(fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          // Big monthly amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currency.format(bill.monthlyPayment),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(width: 8),
              Text('monthly', style: TextStyle(fontSize: 13, color: p.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_fullDateFmt.format(inst.dueDate)} Due  •  Month ${inst.monthIndex}/${bill.installmentMonths}',
            style: TextStyle(
              fontSize: 12.5,
              color: inst.isOverdue ? p.red : p.textMuted,
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
                  valueColor: p.green,
                ),
              ),
              Expanded(
                child: _LabelValue(
                  label: 'Remaining',
                  value: _currency.format(inst.remaining(bill.monthlyPayment)),
                  valueColor: p.red,
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
              backgroundColor: p.greyBg,
              valueColor: AlwaysStoppedAnimation(p.green),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: TextStyle(fontSize: 11.5, color: p.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          // Amount input, shared by both "Add" and "Withdraw".
          // The large bottom scrollPadding keeps the buttons below the field
          // visible above the keyboard while typing.
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
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
                  icon: Icon(Icons.arrow_downward_rounded, size: 16, color: p.red),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.red,
                    side: BorderSide(color: p.red),
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
          const SizedBox(height: 10),
          // One-tap pay: no need to type the amount.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markPaid(context),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text('Mark as Paid  •  ${_currency.format(inst.remaining(bill.monthlyPayment))}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
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
    final p = context.pal;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
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
    final p = context.pal;
    return AppCard(
      child: Row(
        children: [
          IconBadge(icon: Icons.check_rounded, color: p.green, background: p.greenBg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                const SizedBox(height: 2),
                Text(
                  'All ${bill.installmentMonths} months paid • ${_currency.format(bill.totalBill)}',
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
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
