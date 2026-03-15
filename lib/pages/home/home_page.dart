import 'package:flutter/material.dart';

import '../transactions/transactions_page.dart';
import '../contacts/contacts_page.dart';
import '../profile/profile_page.dart';
import '../add_record/add_record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    TransactionsPage(),
    ContactsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddRecord,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '流水'),
          NavigationDestination(icon: Icon(Icons.people), label: '人脉'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  void _onAddRecord() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRecordPage()),
    );
  }
}
