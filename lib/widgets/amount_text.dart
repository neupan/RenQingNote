import 'package:flutter/material.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    required this.isIncome,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? Colors.green : Colors.red;
    final prefix = isIncome ? '+' : '-';
    return Text(
      '$prefix¥${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
      style: (style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
          .copyWith(color: color),
    );
  }
}
