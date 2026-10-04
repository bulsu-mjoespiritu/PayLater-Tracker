import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeTone { red, green, blue, grey }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeTone tone;

  const StatusBadge._(this.text, this.tone);

  factory StatusBadge.forLabel(String label) {
    if (label.contains('Overdue')) return StatusBadge._(label, BadgeTone.red);
    switch (label) {
      case 'Unpaid':
      case 'Deleted':
        return StatusBadge._(label, BadgeTone.red);
      case 'Paid':
      case 'Completed':
        return StatusBadge._(label, BadgeTone.green);
      case 'In Progress':
        return StatusBadge._(label, BadgeTone.blue);
      default:
        return StatusBadge._(label, BadgeTone.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    late final Color color;
    late final Color background;
    switch (tone) {
      case BadgeTone.red:
        color = p.red;
        background = p.redBg;
        break;
      case BadgeTone.green:
        color = p.green;
        background = p.greenBg;
        break;
      case BadgeTone.blue:
        color = p.blue;
        background = p.blueBg;
        break;
      case BadgeTone.grey:
        color = AppColors.grey;
        background = p.greyBg;
        break;
    }
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
