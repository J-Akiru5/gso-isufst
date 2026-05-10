import 'package:flutter/material.dart';

class BorrowingDetailScreen extends StatelessWidget {
  final String id;
  const BorrowingDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Loan #$id')),
        body: const Center(child: Text('Borrowing detail\n(Phase 3)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
      );
}
