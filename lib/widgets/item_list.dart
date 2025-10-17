import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../models/packing_item.dart' as model;
import '../widgets/add_item_dialog.dart';

class ItemList extends StatelessWidget {
  final String bagId;

  const ItemList({super.key, required this.bagId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bag = packingProvider.bags.firstWhere((bag) => bag.id == bagId);
        final filteredItems = packingProvider.getFilteredItems(bagId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      bag.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bag.items.length}개 아이템',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, bagId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('아이템 추가'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyState(
                      hasSearchQuery: packingProvider.searchQuery.isNotEmpty,
                      onAddItem: () => _showAddItemDialog(context, bagId),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ItemCard(
                          item: item,
                          bagId: bagId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, String bagId) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(bagId: bagId),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onAddItem;

  const _EmptyState({
    required this.hasSearchQuery,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? '검색 결과가 없습니다' : '아이템이 없습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery ? '다른 검색어를 시도해보세요' : '첫 번째 아이템을 추가해보세요',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!hasSearchQuery) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('아이템 추가'),
            ),
          ],
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final model.PackingItem item;
  final String bagId;

  const ItemCard({
    super.key,
    required this.item,
    required this.bagId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: item.packed,
              onChanged: (_) {
                Provider.of<PackingProvider>(context, listen: false)
                    .toggleItemPacked(bagId, item.id);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: item.packed ? TextDecoration.lineThrough : null,
                            color: item.packed 
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              item.packed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.packed ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Provider.of<PackingProvider>(context, listen: false)
                    .removeItem(bagId, item.id);
              },
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
