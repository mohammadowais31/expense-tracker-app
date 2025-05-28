class TransactionModel {
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String type;

  TransactionModel({
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
  });
}
