import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double total;
  final double income;
  final double expenses;
  final VoidCallback? onAddIncome;

  const BalanceCard({
    super.key,
    required this.total,
    required this.income,
    required this.expenses,
    this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.pink, Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Text(
            "\Rs${total.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubBalance("Income", income, Colors.green, onAddIncome),
              _buildSubBalance("Expenses", expenses, Colors.red, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubBalance(String label, double amount, Color color, VoidCallback? onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Row(
          children: [
            Text(
              "\Rs${amount.toStringAsFixed(2)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (onAdd != null)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

