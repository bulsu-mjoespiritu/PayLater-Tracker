import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
final _dateFmt = DateFormat('MMM dd, yyyy');

class AddBillScreen extends StatefulWidget {
  /// Pass an existing bill to edit it instead of creating a new one.
  final Bill? billToEdit;

  const AddBillScreen({super.key, this.billToEdit});

  bool get isEditing => billToEdit != null;

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _monthlyController;
  final _initialSavedController = TextEditingController(text: '0');

  late int _installmentMonths;
  late DateTime _dueDate;

  double get _monthlyPayment => double.tryParse(_monthlyController.text.trim()) ?? 0;
  double get _totalBill => _monthlyPayment * _installmentMonths;

  @override
  void initState() {
    super.initState();
    final bill = widget.billToEdit;
    _nameController = TextEditingController(text: bill?.name ?? '');
    _monthlyController = TextEditingController(
      text: bill != null ? _trimZeros(bill.monthlyPayment) : '',
    );
    // Default to 1 installment month for new bills; prefill when editing.
    _installmentMonths = bill?.installmentMonths ?? 1;
    _dueDate = bill?.firstDueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  String _trimZeros(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyController.dispose();
    _initialSavedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstSelectable = DateTime(today.year, today.month, today.day);
    // Guard against the initialDate falling before firstDate (e.g. editing an
    // older bill), which would otherwise throw an assertion error.
    final safeInitial = _dueDate.isBefore(firstSelectable) ? firstSelectable : _dueDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstSelectable,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a bill name.');
      return;
    }
    if (_monthlyPayment <= 0) {
      _showError('Please enter a valid monthly payment.');
      return;
    }
    final provider = context.read<BillProvider>();

    if (widget.isEditing) {
      provider.editBill(
        billId: widget.billToEdit!.id,
        name: name,
        monthlyPayment: _monthlyPayment,
        installmentMonths: _installmentMonths,
        firstDueDate: _dueDate,
      );
    } else {
      final initialSaved = double.tryParse(_initialSavedController.text.trim()) ?? 0;
      provider.addBill(
        name: name,
        monthlyPayment: _monthlyPayment,
        installmentMonths: _installmentMonths,
        firstDueDate: _dueDate,
        initialSaved: initialSaved,
      );
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Bill' : 'Add New Bill')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _FieldLabel('Bill Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Shopee SPayLater'),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Monthly Payment'),
          TextField(
            controller: _monthlyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '₱  ', hintText: '0.00'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Installment Months'),
          Row(
            children: [1, 3, 6, 12].map((m) {
              final selected = _installmentMonths == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _installmentMonths = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryBlue : AppColors.lightGreyBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$m',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Bill (Auto-calculated)',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _currency.format(_totalBill),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(widget.isEditing ? 'Due Date (Month 1)' : 'Due Date (First Installment)'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(color: AppColors.lightGreyBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(_dateFmt.format(_dueDate), style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: 18),
            const _FieldLabel('Initial Saved (Optional)'),
            TextField(
              controller: _initialSavedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '₱  ', hintText: '0.00'),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              'Progress already saved on this bill will be kept.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(widget.isEditing ? 'Update Bill' : 'Save Bill'),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }
}
