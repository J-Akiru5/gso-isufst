import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BorrowingListScreen extends StatelessWidget {
  const BorrowingListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Equipment Borrowing')),
        body: const Center(child: Text('Borrowing list\n(Phase 3)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/borrowing/new'),
          icon: const Icon(Icons.add),
          label: const Text('New Request'),
        ),
      );
}
