import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../models/transaction.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/status_badge.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dateFmt = DateFormat('MMM dd, yyyy');
final _dateTimeFmt = DateFormat('MMM dd, yyyy  •  h:mm a');

/// History tab: two sub-tabs — past Bills (completed/deleted) and a
/// timestamped Transactions log of every Add/Withdraw action.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: TabBar(
            labelColor: p.blue,
            unselectedLabelColor: p.textMuted,
            indicatorColor: p.blue,
            dividerColor: p.divider,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Bills'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BillsHistoryTab(),
            _TransactionsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bills tab — completed & deleted bills
// ---------------------------------------------------------------------------

class _BillsHistoryTab extends StatelessWidget {
  const _BillsHistoryTab();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<BillProvider>().history;

    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No past bills yet',
        subtitle: 'Completed and deleted bills will show up here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: history.length,
      itemBuilder: (context, index) => _BillHistoryCard(bill: history[index]),
    );
  }
}

class _BillHistoryCard extends StatelessWidget {
  final Bill bill;
  const _BillHistoryCard({required this.bill});

  Future<void> _confirmPermanentDelete(BuildContext context) async {
    final p = context.pal;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('"${bill.name}" will be removed from History for good. This can\'t be undone.'),
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
      context.read<BillProvider>().deleteFromHistory(bill.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${bill.name}" deleted permanently')),
      );
    }
  }

  void _restore(BuildContext context) {
    context.read<BillProvider>().restoreFromHistory(bill.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${bill.name}" restored to active bills')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isCompleted = bill.archiveReason == 'Completed';
    final paidCount = bill.paidCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: isCompleted ? Icons.check_rounded : Icons.delete_outline_rounded,
                color: isCompleted ? p.green : p.red,
                background: isCompleted ? p.greenBg : p.redBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                    const SizedBox(height: 2),
                    Text(
                      'Total Bill: ${_currency.format(bill.totalBill)}',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge.forLabel(bill.archiveReason ?? 'Archived'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'Months Paid',
                  value: '$paidCount of ${bill.installmentMonths}',
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: isCompleted ? 'Completed On' : 'Deleted On',
                  value: bill.archivedAt != null ? _dateFmt.format(bill.archivedAt!) : '—',
                ),
              ),
            ],
          ),
          if (isCompleted && bill.excessCredit > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.greenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You paid ${_currency.format(bill.excessCredit)} extra on this bill — that\'s left over after every month was covered.',
                style: TextStyle(fontSize: 12.5, color: p.green, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _restore(context),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.blue,
                    side: BorderSide(color: p.blue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmPermanentDelete(context),
                  icon: const Icon(Icons.delete_forever_outlined, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.red,
                    side: BorderSide(color: p.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions tab — dated log of every Add / Withdraw action
// ---------------------------------------------------------------------------

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<BillProvider>().transactions;

    if (transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        subtitle: 'Every time you add or withdraw savings, it\'ll be logged here with the date and time.',
      );
    }

    // Group by calendar day so the log reads like a statement.
    final Map<String, List<SavingsTransaction>> grouped = {};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.timestamp);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dayKeys = grouped.keys.toList(); // already newest-first since source list is
    final p = context.pal;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: dayKeys.length,
      itemBuilder: (context, index) {
        final key = dayKeys[index];
        final dayTransactions = grouped[key]!;
        final dayLabel = DateFormat('EEEE, MMM dd, yyyy').format(dayTransactions.first.timestamp);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                dayLabel,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.textMuted),
              ),
            ),
            ...dayTransactions.map((t) => _TransactionTile(transaction: t)),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final SavingsTransaction transaction;
  const _TransactionTile({required this.transaction});

  Future<void> _confirmDelete(BuildContext context) async {
    final p = context.pal;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo this transaction?'),
        content: Text(
          'This will reverse the ${transaction.type.label.toLowerCase()} of '
          '${_currency.format(transaction.amount)} on "${transaction.billName}" '
          '(Month ${transaction.monthIndex}) and remove it from the log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.red),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<BillProvider>().deleteTransaction(transaction.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction undone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isAdd = transaction.type == TransactionType.add;
    final color = isAdd ? p.green : p.red;
    final bg = isAdd ? p.greenBg : p.redBg;
    final sign = isAdd ? '+' : '-';

    return AppCard(
      child: Row(
        children: [
          IconBadge(
            icon: isAdd ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            background: bg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.billName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
                const SizedBox(height: 2),
                Text(
                  '${transaction.type.label} • Month ${transaction.monthIndex} of ${transaction.installmentMonths}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateTimeFmt.format(transaction.timestamp),
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_currency.format(transaction.amount)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
              CardIconButton(
                icon: Icons.close_rounded,
                color: p.textMuted,
                tooltip: 'Undo & delete',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
