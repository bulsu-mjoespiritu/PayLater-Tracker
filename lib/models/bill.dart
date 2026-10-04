/// Status of a single monthly installment within a Bill.
enum InstallmentStatus {
  /// Fully paid (saved amount reached the monthly payment).
  paid,

  /// The current installment the user is actively saving toward.
  active,

  /// A future installment not yet reached.
  pending,
}

extension InstallmentStatusLabel on InstallmentStatus {
  String get label {
    switch (this) {
      case InstallmentStatus.paid:
        return 'Paid';
      case InstallmentStatus.active:
        return 'Unpaid';
      case InstallmentStatus.pending:
        return 'Pending';
    }
  }
}

/// A single month's installment for a Bill.
class Installment {
  final int monthIndex; // 1-based, e.g. 1 of 3
  final DateTime dueDate;
  double saved;
  InstallmentStatus status;

  Installment({
    required this.monthIndex,
    required this.dueDate,
    this.saved = 0,
    this.status = InstallmentStatus.pending,
  });

  double remaining(double monthlyPayment) {
    final r = monthlyPayment - saved;
    return r < 0 ? 0 : r;
  }

  /// True if this installment isn't paid yet and its due date has passed
  /// (compared by calendar day, not time-of-day).
  bool get isOverdue {
    if (status == InstallmentStatus.paid) return false;
    final today = DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return todayDay.isAfter(dueDay);
  }

  /// Number of full calendar days past the due date. 0 if not overdue.
  int get daysOverdue {
    if (!isOverdue) return 0;
    final today = DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return todayDay.difference(dueDay).inDays;
  }

  /// Label to show in the UI: overrides the plain status label with
  /// e.g. "3 Days Overdue" once the due date has passed.
  String get displayLabel {
    if (isOverdue) {
      final d = daysOverdue;
      return d == 1 ? '1 Day Overdue' : '$d Days Overdue';
    }
    return status.label;
  }

  double progress(double monthlyPayment) {
    if (monthlyPayment <= 0) return 0;
    final p = saved / monthlyPayment;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  Map<String, dynamic> toJson() => {
        'monthIndex': monthIndex,
        'dueDate': dueDate.toIso8601String(),
        'saved': saved,
        'status': status.name,
      };

  factory Installment.fromJson(Map<String, dynamic> json) => Installment(
        monthIndex: json['monthIndex'] as int,
        dueDate: DateTime.parse(json['dueDate'] as String),
        saved: (json['saved'] as num).toDouble(),
        status: InstallmentStatus.values.byName(json['status'] as String),
      );
}

/// Represents one SPayLater bill split into N monthly installments.
class Bill {
  final String id;
  String name;
  double monthlyPayment;
  int installmentMonths;
  DateTime firstDueDate;
  late List<Installment> installments;

  /// Set when a bill is archived into History (either auto-completed or
  /// manually deleted from the Home screen). Null while the bill is active.
  DateTime? archivedAt;

  /// 'Completed' or 'Deleted' — only meaningful once archivedAt is set.
  String? archiveReason;

  /// Extra money left over after every installment has been fully paid —
  /// e.g. the last installment needed ₱267.63 more, but the user added
  /// ₱300, so ₱32.37 has nowhere left to go and is tracked here instead
  /// of being silently discarded.
  double excessCredit;

  Bill({
    required this.id,
    required this.name,
    required this.monthlyPayment,
    required this.installmentMonths,
    required this.firstDueDate,
    double initialSaved = 0,
    List<Installment>? existingInstallments,
    this.excessCredit = 0,
  }) {
    if (existingInstallments != null) {
      installments = existingInstallments;
      return;
    }
    installments = List.generate(installmentMonths, (i) {
      final due = DateTime(firstDueDate.year, firstDueDate.month + i, firstDueDate.day);
      return Installment(
        monthIndex: i + 1,
        dueDate: due,
        status: i == 0 ? InstallmentStatus.active : InstallmentStatus.pending,
      );
    });
    if (initialSaved > 0 && installments.isNotEmpty) {
      installments.first.saved = initialSaved;
      if (installments.first.saved >= monthlyPayment) {
        installments.first.saved = monthlyPayment;
        installments.first.status = InstallmentStatus.paid;
        if (installments.length > 1) {
          installments[1].status = InstallmentStatus.active;
        }
      }
    }
  }

  double get totalBill => monthlyPayment * installmentMonths;

  int get paidCount => installments.where((i) => i.status == InstallmentStatus.paid).length;

  bool get isCompleted => paidCount == installmentMonths;

  /// Total unpaid balance for this bill = total bill minus all fully-paid installments.
  double get totalUnpaidBalance => totalBill - (paidCount * monthlyPayment);

  /// Money set aside on installments that aren't paid yet.
  double get savedTowardUnpaid => installments
      .where((i) => i.status != InstallmentStatus.paid)
      .fold(0.0, (sum, i) => sum + i.saved);

  /// The installment the user is currently saving toward (first non-paid one).
  Installment? get currentInstallment {
    for (final inst in installments) {
      if (inst.status != InstallmentStatus.paid) return inst;
    }
    return null; // all paid
  }

  String get statusLabel => isCompleted ? 'Completed' : 'In Progress';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlyPayment': monthlyPayment,
        'installmentMonths': installmentMonths,
        'firstDueDate': firstDueDate.toIso8601String(),
        'installments': installments.map((i) => i.toJson()).toList(),
        'archivedAt': archivedAt?.toIso8601String(),
        'archiveReason': archiveReason,
        'excessCredit': excessCredit,
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    final bill = Bill(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      installmentMonths: json['installmentMonths'] as int,
      firstDueDate: DateTime.parse(json['firstDueDate'] as String),
      existingInstallments: (json['installments'] as List)
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList(),
      excessCredit: (json['excessCredit'] as num?)?.toDouble() ?? 0,
    );
    bill.archivedAt = json['archivedAt'] != null ? DateTime.parse(json['archivedAt'] as String) : null;
    bill.archiveReason = json['archiveReason'] as String?;
    return bill;
  }
}
