import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../widgets/bag_card.dart';
import '../widgets/item_list.dart';
import '../widgets/add_bag_dialog.dart';

class PackingManager extends StatelessWidget {
  const PackingManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'cherry pick',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SearchBar(),
              const SizedBox(height: 24),
              _BagOverview(),
              const SizedBox(height: 24),
              _BagTabs(),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            decoration: InputDecoration(
              hintText: '물건 검색...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: packingProvider.setSearchQuery,
          ),
        );
      },
    );
  }
}

class _BagOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: packingProvider.bags.length + 1,
            itemBuilder: (context, index) {
              if (index == packingProvider.bags.length) {
                return _AddBagCard();
              }
              final bag = packingProvider.bags[index];
              return BagCard(
                bag: bag,
                isSelected: packingProvider.selectedBag == bag.id,
                onTap: () => packingProvider.setSelectedBag(bag.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _AddBagCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddBagDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                '가방 추가',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddBagDialog(),
    );
  }
}

class _BagTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: packingProvider.bags.map((bag) => Tab(text: bag.name)).toList(),
              onTap: (index) => packingProvider.setSelectedBag(packingProvider.bags[index].id),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: TabBarView(
                children: packingProvider.bags.map((bag) => ItemList(bagId: bag.id)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
