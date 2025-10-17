import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/item_scanner.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('cherry pick'),
        centerTitle: true,
        leading: const AppHeader(),
        leadingWidth: 200,
      ),
      body: const ItemScanner(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }
}
