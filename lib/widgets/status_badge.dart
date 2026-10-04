import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.background,
  });

  factory StatusBadge.forLabel(String label) {
    if (label.contains('Overdue')) {
      return StatusBadge(text: label, color: AppColors.red, background: AppColors.lightRedBg);
    }
    switch (label) {
      case 'Unpaid':
        return StatusBadge(text: label, color: AppColors.red, background: AppColors.lightRedBg);
      case 'Pending':
        return StatusBadge(text: label, color: AppColors.grey, background: AppColors.lightGreyBg);
      case 'Paid':
        return StatusBadge(text: label, color: AppColors.green, background: AppColors.lightGreenBg);
      case 'In Progress':
        return StatusBadge(text: label, color: AppColors.primaryBlue, background: AppColors.lightBlueBg);
      case 'Completed':
        return StatusBadge(text: label, color: AppColors.green, background: AppColors.lightGreenBg);
      case 'Deleted':
        return StatusBadge(text: label, color: AppColors.red, background: AppColors.lightRedBg);
      default:
        return StatusBadge(text: label, color: AppColors.grey, background: AppColors.lightGreyBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
