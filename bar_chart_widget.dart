import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  final List<double> amounts;
  final List<String> labels;

  const BarChartWidget({super.key, required this.amounts, required this.labels});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: amounts.reduce((a, b) => a > b ? a : b) + 50,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(labels[index], style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          amounts.length,
          (index) => BarChartGroupData(x: index, barRods: [
            BarChartRodData(
              toY: amounts[index],
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(4),
              width: 18,
            ),
          ]),
        ),
      ),
    );
  }
}
