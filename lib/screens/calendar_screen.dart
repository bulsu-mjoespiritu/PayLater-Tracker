import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dayFmt = DateFormat('dd');
final _monthFmt = DateFormat('MMM');
final _weekdayFmt = DateFormat('EEEE');
final _fullDateFmt = DateFormat('MMMM dd, yyyy');

class _DueEntry {
  final Bill bill;
  final Installment installment;
  _DueEntry(this.bill, this.installment);
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;

    final entries = <_DueEntry>[];
    for (final bill in bills) {
      for (final inst in bill.installments) {
        entries.add(_DueEntry(bill, inst));
      }
    }
    entries.sort((a, b) => a.installment.dueDate.compareTo(b.installment.dueDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: entries.isEmpty
          ? const Center(child: Text('No upcoming due dates', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: entries.length,
              itemBuilder: (context, index) => _DueDateTile(entry: entries[index]),
            ),
    );
  }
}

class _DueDateTile extends StatelessWidget {
  final _DueEntry entry;
  const _DueDateTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final inst = entry.installment;
    final bill = entry.bill;
    final isPaid = inst.status == InstallmentStatus.paid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isPaid ? AppColors.lightGreenBg : AppColors.lightBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_dayFmt.format(inst.dueDate),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isPaid ? AppColors.green : AppColors.primaryBlue)),
                Text(_monthFmt.format(inst.dueDate).toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.green : AppColors.primaryBlue)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  '${_weekdayFmt.format(inst.dueDate)} • Month ${inst.monthIndex} of ${bill.installmentMonths}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(_currency.format(bill.monthlyPayment),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
          ),
          StatusBadge.forLabel(inst.status.label),
        ],
      ),
    );
  }
}
