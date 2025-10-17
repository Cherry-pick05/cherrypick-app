import 'package:flutter/material.dart';
import '../widgets/simple_header.dart';
import '../widgets/bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('cherry pick'),
        centerTitle: true,
        leading: const SimpleHeader(),
        leadingWidth: 200,
      ),
      body: const Center(
        child: Text('홈 화면'),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
  }
}
