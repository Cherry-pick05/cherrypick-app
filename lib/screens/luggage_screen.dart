import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/packing_manager.dart';

class LuggageScreen extends StatelessWidget {
  const LuggageScreen({super.key});

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
      body: const PackingManager(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
  }
}
