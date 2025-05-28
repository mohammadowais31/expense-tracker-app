import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/bar_chart_widget.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Stream<QuerySnapshot> getTransactionsStream(String type) {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user!.uid)
        .where('type', isEqualTo: type)
        .snapshots();
  }

  double getTotalAmount(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0, (sum, doc) => sum + (doc['amount'] as num).abs());
  }

  List<double> getAmounts(List<QueryDocumentSnapshot> docs) {
    final Map<String, double> map = {};
    for (var doc in docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String day = DateFormat.MMMd().format(date);
      map[day] = (map[day] ?? 0) + (doc['amount'] as num).abs();
    }
    return map.values.toList();
  }

  List<String> getLabels(List<QueryDocumentSnapshot> docs) {
    final Map<String, double> map = {};
    for (var doc in docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String day = DateFormat.MMMd().format(date);
      map[day] = (map[day] ?? 0) + (doc['amount'] as num).abs();
    }
    return map.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Income"),
            Tab(text: "Expenses"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ["Income", "Expense"].map((type) {
          return StreamBuilder<QuerySnapshot>(
            stream: getTransactionsStream(type),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No transactions found."));
              }

              final docs = snapshot.data!.docs;
              final labels = getLabels(docs);
              final amounts = getAmounts(docs);
              final total = getTotalAmount(docs);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Total $type: \$${total.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChartWidget(amounts: amounts, labels: labels),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final doc = docs[i];
                          return ListTile(
                            leading: Icon(
                              type == "Income" ? Icons.attach_money : Icons.money_off,
                              color: type == "Income" ? Colors.green : Colors.red,
                            ),
                            title: Text(doc['category']),
                            subtitle: Text(DateFormat.yMMMd().format((doc['date'] as Timestamp).toDate())),
                            trailing: Text(
                              "\$${(doc['amount'] as num).abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: type == "Income" ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
