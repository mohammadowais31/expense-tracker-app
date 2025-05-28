import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../widgets/balance_card.dart';
import 'add_expense_screen.dart';
import 'transactions_screen.dart';
import 'sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String displayName = "User";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          displayName = data['name'] ?? user.email?.split('@').first ?? 'User';
          isLoading = false;
        });
      } else {
        setState(() {
          displayName = user.email?.split('@').first ?? 'User';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateIncome(double newIncome, double addedAmount) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    // Update total income in 'users' collection
    await firestore.collection('users').doc(uid).set({
      'income': newIncome,
    }, SetOptions(merge: true));

    // Log income in 'income' collection
    await firestore.collection('income').add({
      'userId': uid,
      'income': addedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add income to 'transactions' collection for tile display
    await firestore.collection('transactions').add({
      'userId': uid,
      'amount': addedAmount,
      'category': 'Income', // or 'Salary', 'Other', etc.
      'date': Timestamp.now(),
      'note': 'Added Income',
      'type': 'Income',
    });
  }
}

  void _showAddIncomeDialog(double currentIncome) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Income'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter income amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = double.tryParse(controller.text);
                if (input != null && input > 0) {
                  final newIncome = currentIncome + input;
                  await _updateIncome(newIncome, input);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Stream<QuerySnapshot> transactionStream = FirebaseFirestore.instance
    .collection('transactions')
    .where('userId', isEqualTo: user.uid)
    .snapshots();

    final List<Widget> screens = [
      StreamBuilder<QuerySnapshot>(
        stream: transactionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final transactions =
              docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                double amount = 0.0;
                try {
                  amount =
                      data['amount'] is int
                          ? (data['amount'] as int).toDouble()
                          : (data['amount'] as double);
                } catch (_) {}

                // Handle possible null or missing 'date' safely
                DateTime txDate;
                try {
                  txDate =
                      (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                } catch (_) {
                  txDate = DateTime.now();
                }

                return TransactionModel(
                  category: data['category'] ?? '',
                  amount: amount,
                  date: txDate,
                  note: data['note'] ?? '',
                  type: data['type'] ?? 'Expense',
                );
              }).toList();

          final expenses = docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((data) => data['type'] == 'Expense')
              .fold(0.0, (sum, data) {
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                return sum + amount;
              });

          return StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final double income = (userData['income'] ?? 0).toDouble();
              final total = income - expenses;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BalanceCard(
                      total: total,
                      income: income,
                      expenses: expenses,
                      onAddIncome: () => _showAddIncomeDialog(income),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child:
                          transactions.isEmpty
                              ? const Center(
                                child: Text("No transactions yet."),
                              )
                              : ListView.builder(
                                itemCount: transactions.length,
                                itemBuilder:
                                    (ctx, i) =>
                                        TransactionTile(tx: transactions[i]),
                              ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      const TransactionsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(" $displayName"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          setState(() {}); // Refresh screen after returning
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}

// ====== TransactionTile Widget Code ======
class TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final categoryIcons = {
      "Food": Icons.fastfood,
      "Shopping": Icons.shopping_bag,
      "Entertainment": Icons.movie,
      "Travel": Icons.flight,
    };

    final icon = categoryIcons[tx.category] ?? Icons.money;

    String dateLabel;
    final now = DateTime.now();
    if (tx.date.day == now.day &&
        tx.date.month == now.month &&
        tx.date.year == now.year) {
      dateLabel = "Today";
    } else if (tx.date.day == now.subtract(const Duration(days: 1)).day &&
        tx.date.month == now.month &&
        tx.date.year == now.year) {
      dateLabel = "Yesterday";
    } else {
      dateLabel = DateFormat.yMMMd().format(tx.date);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple.shade100,
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title: Text(tx.category),
      subtitle: Text(dateLabel),
      trailing: Text(
        tx.type == 'Income' ? "+\Rs${tx.amount}" : "-\Rs${tx.amount}",
        style: TextStyle(
          color: tx.type == 'Income' ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}