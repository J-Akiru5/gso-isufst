import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('Notifications\n(Phase 4)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
}
