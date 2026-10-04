import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../models/transaction.dart';

/// App-wide state manager for bills. Handles adding bills, adding savings,
/// the automatic "advance to next installment" logic, and persisting
/// everything to on-device storage so it survives closing the app.
class BillProvider extends ChangeNotifier {
  static const _billsKey = 'sbm_bills_v1';
  static const _historyKey = 'sbm_history_v1';
  static const _transactionsKey = 'sbm_transactions_v1';

  final List<Bill> _bills = [];

  /// Archived bills — either fully completed or manually deleted from Home.
  /// Kept as a record instead of being erased, shown in the History tab.
  final List<Bill> _history = [];

  /// Timestamped log of every "Add saving" / "Withdraw" action, newest first.
  final List<SavingsTransaction> _transactions = [];

  bool _isLoaded = false;

  /// True once saved data has been read from disk. The UI shows a brief
  /// loading state until this flips to true.
  bool get isLoaded => _isLoaded;

  List<Bill> get bills => List.unmodifiable(_bills);

  /// Past bills: auto-completed or manually deleted. Newest first.
  List<Bill> get history => List.unmodifiable(_history);

  /// Full add/withdraw activity log, newest first.
  List<SavingsTransaction> get transactions => List.unmodifiable(_transactions);

  /// Activity log filtered to a single bill, newest first.
  List<SavingsTransaction> transactionsForBill(String billId) =>
      _transactions.where((t) => t.billId == billId).toList();

  /// Bills that still have unpaid installments remaining.
  List<Bill> get activeBills => _bills.where((b) => !b.isCompleted).toList();

  int get activeBillsCount => activeBills.length;

  /// Sum of unpaid balances across every bill.
  double get totalUnpaidBalance => _bills.fold(0.0, (sum, b) => sum + b.totalUnpaidBalance);

  /// Money currently set aside toward unpaid installments across all bills.
  double get totalSavedMoney => _bills.fold(0.0, (sum, b) => sum + b.savedTowardUnpaid);

  /// Mirrors totalUnpaidBalance — shown separately per the dashboard design
  /// (kept as its own getter in case remaining logic ever diverges).
  double get totalRemaining => totalUnpaidBalance;

  /// Reads any previously-saved bills/history/transactions from disk.
  /// Call once at app startup. Starts completely empty if nothing has
  /// been saved yet — no demo/sample data.
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final billsJson = prefs.getString(_billsKey);
    final historyJson = prefs.getString(_historyKey);
    final txJson = prefs.getString(_transactionsKey);

    if (billsJson != null) {
      final list = jsonDecode(billsJson) as List;
      _bills.addAll(list.map((e) => Bill.fromJson(e as Map<String, dynamic>)));
    }
    if (historyJson != null) {
      final list = jsonDecode(historyJson) as List;
      _history.addAll(list.map((e) => Bill.fromJson(e as Map<String, dynamic>)));
    }
    if (txJson != null) {
      final list = jsonDecode(txJson) as List;
      _transactions.addAll(list.map((e) => SavingsTransaction.fromJson(e as Map<String, dynamic>)));
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_billsKey, jsonEncode(_bills.map((b) => b.toJson()).toList()));
    await prefs.setString(_historyKey, jsonEncode(_history.map((b) => b.toJson()).toList()));
    await prefs.setString(_transactionsKey, jsonEncode(_transactions.map((t) => t.toJson()).toList()));
  }

  void _logTransaction({
    required Bill bill,
    required Installment installment,
    required TransactionType type,
    required double amount,
  }) {
    _transactions.insert(
      0,
      SavingsTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        billId: bill.id,
        billName: bill.name,
        type: type,
        amount: amount,
        timestamp: DateTime.now(),
        monthIndex: installment.monthIndex,
        installmentMonths: bill.installmentMonths,
      ),
    );
  }

  void addBill({
    required String name,
    required double monthlyPayment,
    required int installmentMonths,
    required DateTime firstDueDate,
    double initialSaved = 0,
  }) {
    final bill = Bill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      monthlyPayment: monthlyPayment,
      installmentMonths: installmentMonths,
      firstDueDate: firstDueDate,
      initialSaved: initialSaved,
    );
    _bills.add(bill);
    notifyListeners();
    unawaited(_persist());
  }

  void removeBill(String billId) {
    _bills.removeWhere((b) => b.id == billId);
    notifyListeners();
    unawaited(_persist());
  }

  /// Adds a saving amount toward a bill's current active installment.
  /// If the amount is more than what's needed to finish the current
  /// installment, the excess automatically rolls forward into the next
  /// installment (and the one after that, and so on) instead of being
  /// discarded. If it rolls past the very last installment, it's kept as
  /// the bill's `excessCredit` so the user can see how much extra they paid.
  void addSaving(String billId, double amount) {
    if (amount <= 0) return;
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return;
    final bill = _bills[billIndex];

    final startInstallment = bill.currentInstallment;
    if (startInstallment == null) return; // already fully paid

    double remaining = amount;
    while (remaining > 0) {
      final target = bill.currentInstallment;
      if (target == null) {
        // Every installment is paid — nowhere left for the excess to go,
        // so keep it on record as credit instead of discarding it.
        bill.excessCredit += remaining;
        remaining = 0;
        break;
      }
      final needed = bill.monthlyPayment - target.saved;
      if (remaining >= needed) {
        target.saved = bill.monthlyPayment;
        target.status = InstallmentStatus.paid;
        remaining -= needed;
        final nextIdx = bill.installments.indexOf(target) + 1;
        if (nextIdx < bill.installments.length) {
          bill.installments[nextIdx].status = InstallmentStatus.active;
        }
      } else {
        target.saved += remaining;
        remaining = 0;
      }
    }

    _logTransaction(
      bill: bill,
      installment: startInstallment,
      type: TransactionType.add,
      amount: amount,
    );

    // Once every installment is paid, move the bill out of the active list
    // and into History automatically.
    if (bill.isCompleted) {
      _archiveBill(bill, 'Completed');
    }

    notifyListeners();
    unawaited(_persist());
  }

  /// Withdraws money the user already saved toward the current installment
  /// (e.g. they saved ₱250 but need ₱50 back for something else). The
  /// withdrawal is capped so saved never goes below ₱0, and never affects
  /// installments that are already marked Paid.
  void withdrawSaving(String billId, double amount) {
    if (amount <= 0) return;
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return;
    final bill = _bills[billIndex];

    final current = bill.currentInstallment;
    if (current == null) return; // already fully paid, nothing to withdraw

    final before = current.saved;
    current.saved -= amount;
    if (current.saved < 0) current.saved = 0;
    final actualWithdrawn = before - current.saved;

    if (actualWithdrawn > 0) {
      _logTransaction(
        bill: bill,
        installment: current,
        type: TransactionType.withdraw,
        amount: actualWithdrawn,
      );
    }

    notifyListeners();
    unawaited(_persist());
  }

  /// Deletes an active bill from Home/Bills and files it under History
  /// instead of destroying it, so the record isn't lost.
  void deleteBill(String billId) {
    final idx = _bills.indexWhere((b) => b.id == billId);
    if (idx == -1) return;
    _archiveBill(_bills[idx], 'Deleted');
    notifyListeners();
    unawaited(_persist());
  }

  /// Permanently removes a bill from History.
  void deleteFromHistory(String billId) {
    _history.removeWhere((b) => b.id == billId);
    notifyListeners();
    unawaited(_persist());
  }

  void _archiveBill(Bill bill, String reason) {
    _bills.removeWhere((b) => b.id == bill.id);
    bill.archivedAt = DateTime.now();
    bill.archiveReason = reason;
    _history.insert(0, bill);
  }

  /// Updates an existing bill's details. Preserves already-saved amounts
  /// and paid/active status for installments that still exist after the
  /// edit; new installments (if months increased) start out pending, and
  /// due dates are recalculated from the new first due date.
  void editBill({
    required String billId,
    required String name,
    required double monthlyPayment,
    required int installmentMonths,
    required DateTime firstDueDate,
  }) {
    final idx = _bills.indexWhere((b) => b.id == billId);
    if (idx == -1) return;
    final bill = _bills[idx];

    bill.name = name;
    bill.monthlyPayment = monthlyPayment;
    bill.firstDueDate = firstDueDate;

    final oldInstallments = bill.installments;
    final newInstallments = <Installment>[];

    for (int i = 0; i < installmentMonths; i++) {
      final due = DateTime(firstDueDate.year, firstDueDate.month + i, firstDueDate.day);
      if (i < oldInstallments.length) {
        final old = oldInstallments[i];
        newInstallments.add(Installment(
          monthIndex: i + 1,
          dueDate: due,
          saved: old.saved,
          status: old.status,
        ));
      } else {
        newInstallments.add(Installment(monthIndex: i + 1, dueDate: due));
      }
    }

    // Make sure exactly one installment is "active" if the bill isn't
    // fully paid (covers edge cases from shrinking/growing the month count).
    final allPaid = newInstallments.every((i) => i.status == InstallmentStatus.paid);
    final hasActive = newInstallments.any((i) => i.status == InstallmentStatus.active);
    if (!allPaid && !hasActive) {
      for (final inst in newInstallments) {
        if (inst.status != InstallmentStatus.paid) {
          inst.status = InstallmentStatus.active;
          break;
        }
      }
    }

    bill.installmentMonths = installmentMonths;
    bill.installments = newInstallments;

    if (bill.isCompleted) {
      _archiveBill(bill, 'Completed');
    }

    notifyListeners();
    unawaited(_persist());
  }

  /// Directly marks the current installment as paid regardless of saved amount.
  void markCurrentAsPaid(String billId) {
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return;
    final bill = _bills[billIndex];
    final current = bill.currentInstallment;
    if (current == null) return;

    final remaining = bill.monthlyPayment - current.saved;
    if (remaining > 0) {
      addSaving(billId, remaining);
    } else {
      // Already saved enough (e.g. the monthly amount was lowered after
      // saving) — just flip it to Paid.
      setInstallmentSaved(billId, current.monthIndex, bill.monthlyPayment);
    }
  }

  /// Finds a bill by id, checking active bills first, then History.
  /// Returns null (and which list, via [fromHistory]) if not found in either.
  Bill? _findBillAnywhere(String billId, {required void Function(bool fromHistory) onFound}) {
    final activeIdx = _bills.indexWhere((b) => b.id == billId);
    if (activeIdx != -1) {
      onFound(false);
      return _bills[activeIdx];
    }
    final histIdx = _history.indexWhere((b) => b.id == billId);
    if (histIdx != -1) {
      onFound(true);
      return _history[histIdx];
    }
    return null;
  }

  /// Directly corrects the saved amount for one specific installment — use
  /// this to fix a mistake, e.g. accidentally tapping "+ Add" with the
  /// wrong number and marking a month Paid too early. Works even if the
  /// mistake was on the bill's last installment and it already got
  /// auto-archived to History as "Completed": in that case the bill is
  /// automatically restored to the active list once it's no longer fully paid.
  void setInstallmentSaved(String billId, int monthIndex, double newSaved) {
    bool wasArchived = false;
    final bill = _findBillAnywhere(billId, onFound: (fromHistory) => wasArchived = fromHistory);
    if (bill == null) return;

    final instIdx = bill.installments.indexWhere((i) => i.monthIndex == monthIndex);
    if (instIdx == -1) return;

    final clamped = newSaved < 0
        ? 0.0
        : (newSaved > bill.monthlyPayment ? bill.monthlyPayment : newSaved);
    bill.installments[instIdx].saved = clamped;
    bill.installments[instIdx].status =
        clamped >= bill.monthlyPayment ? InstallmentStatus.paid : InstallmentStatus.pending;

    // Re-derive exactly one "active" installment: the first non-paid one.
    // Everything after it goes back to pending, undoing any downstream
    // auto-advance that shouldn't have happened.
    bool activeSet = false;
    for (final inst in bill.installments) {
      if (inst.status == InstallmentStatus.paid) continue;
      if (!activeSet) {
        inst.status = InstallmentStatus.active;
        activeSet = true;
      } else {
        inst.status = InstallmentStatus.pending;
      }
    }

    if (bill.isCompleted) {
      if (!wasArchived) _archiveBill(bill, 'Completed');
    } else if (wasArchived) {
      // No longer fully paid — pull it back out of History automatically.
      _history.removeWhere((b) => b.id == bill.id);
      bill.archivedAt = null;
      bill.archiveReason = null;
      bill.excessCredit = 0; // was only meaningful once fully paid
      _bills.add(bill);
    }

    notifyListeners();
    unawaited(_persist());
  }

  /// Moves a bill out of History and back into the active list — e.g. if
  /// it was deleted by mistake, or auto-completed by mistake and the user
  /// wants to keep tracking it.
  void restoreFromHistory(String billId) {
    final idx = _history.indexWhere((b) => b.id == billId);
    if (idx == -1) return;
    final bill = _history.removeAt(idx);
    bill.archivedAt = null;
    bill.archiveReason = null;
    bill.excessCredit = 0;
    _bills.add(bill);
    notifyListeners();
    unawaited(_persist());
  }

  /// Permanently deletes one Add/Withdraw log entry AND reverses its
  /// effect on the bill it applied to — this is how an accidental Add or
  /// Withdraw gets undone, not just hidden from the log.
  void deleteTransaction(String transactionId) {
    final txIdx = _transactions.indexWhere((t) => t.id == transactionId);
    if (txIdx == -1) return;
    final tx = _transactions[txIdx];

    final bill = _findBillAnywhere(tx.billId, onFound: (_) {});
    if (bill != null) {
      final instIdx = bill.installments.indexWhere((i) => i.monthIndex == tx.monthIndex);
      if (instIdx != -1) {
        final inst = bill.installments[instIdx];
        final reversed = tx.type == TransactionType.add ? inst.saved - tx.amount : inst.saved + tx.amount;
        setInstallmentSaved(bill.id, tx.monthIndex, reversed);
      }
    }

    _transactions.removeAt(txIdx);
    notifyListeners();
    unawaited(_persist());
  }
}
