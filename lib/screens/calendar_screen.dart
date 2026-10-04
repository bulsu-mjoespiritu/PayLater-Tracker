import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dayFmt = DateFormat('dd');
final _monthFmt = DateFormat('MMM');
final _weekdayFmt = DateFormat('EEEE');

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
          ? const EmptyState(icon: Icons.calendar_month_outlined, title: 'No upcoming due dates')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
    final p = context.pal;
    final inst = entry.installment;
    final bill = entry.bill;
    final isPaid = inst.status == InstallmentStatus.paid;
    final tone = isPaid ? p.green : p.blue;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isPaid ? p.greenBg : p.blueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_dayFmt.format(inst.dueDate),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: tone)),
                Text(_monthFmt.format(inst.dueDate).toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tone)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                const SizedBox(height: 2),
                Text(
                  '${_weekdayFmt.format(inst.dueDate)} • Month ${inst.monthIndex} of ${bill.installmentMonths}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 4),
                Text(_currency.format(bill.monthlyPayment),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text)),
              ],
            ),
          ),
          StatusBadge.forLabel(inst.displayLabel),
        ],
      ),
    );
  }
}
