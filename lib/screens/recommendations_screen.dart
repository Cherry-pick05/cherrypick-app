import 'package:flutter/material.dart';
import '../widgets/simple_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/travel_recommendations.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

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
      body: const TravelRecommendations(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }
}
