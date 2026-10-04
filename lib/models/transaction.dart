/// Whether a logged savings action added money toward a bill, or pulled
/// previously-saved money back out.
enum TransactionType { add, withdraw }

extension TransactionTypeLabel on TransactionType {
  String get label => this == TransactionType.add ? 'Added' : 'Withdrawn';
}

/// A single timestamped "Add saving" or "Withdraw" action, kept so the user
/// can look back and see exactly when they moved money and how much.
class SavingsTransaction {
  final String id;
  final String billId;
  final String billName;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;

  /// Which installment (e.g. Month 2 of 3) this action applied to, captured
  /// at the time of the transaction so the log stays accurate even if the
  /// bill is later edited or deleted.
  final int monthIndex;
  final int installmentMonths;

  SavingsTransaction({
    required this.id,
    required this.billId,
    required this.billName,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.monthIndex,
    required this.installmentMonths,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'billId': billId,
        'billName': billName,
        'type': type.name,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'monthIndex': monthIndex,
        'installmentMonths': installmentMonths,
      };

  factory SavingsTransaction.fromJson(Map<String, dynamic> json) => SavingsTransaction(
        id: json['id'] as String,
        billId: json['billId'] as String,
        billName: json['billName'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        monthIndex: json['monthIndex'] as int,
        installmentMonths: json['installmentMonths'] as int,
      );
}
