import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../models/transaction.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryBlue,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
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
      return const _EmptyState(
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
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
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
    final isCompleted = bill.archiveReason == 'Completed';
    final paidCount = bill.paidCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.lightGreenBg : AppColors.lightRedBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.delete_outline_rounded,
                  color: isCompleted ? AppColors.green : AppColors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Total Bill: ${_currency.format(bill.totalBill)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge.forLabel(bill.archiveReason ?? 'Archived'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
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
                color: AppColors.lightGreenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You paid ${_currency.format(bill.excessCredit)} extra on this bill — that\'s left over after every month was covered.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w700),
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
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
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
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
      return const _EmptyState(
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
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
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
    final isAdd = transaction.type == TransactionType.add;
    final color = isAdd ? AppColors.green : AppColors.red;
    final bg = isAdd ? AppColors.lightGreenBg : AppColors.lightRedBg;
    final sign = isAdd ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(
              isAdd ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.billName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  '${transaction.type.label} • Month ${transaction.monthIndex} of ${transaction.installmentMonths}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateTimeFmt.format(transaction.timestamp),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Undo & delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
