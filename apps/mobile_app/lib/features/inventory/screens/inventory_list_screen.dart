import 'package:flutter/material.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: const Center(child: Text('Inventory list\n(Phase 3)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
      );
}
