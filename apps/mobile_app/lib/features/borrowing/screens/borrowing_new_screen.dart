import 'package:flutter/material.dart';

class BorrowingNewScreen extends StatelessWidget {
  const BorrowingNewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Borrowing Request')),
        body: const Center(child: Text('Borrowing form\n(Phase 3)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
      );
}
