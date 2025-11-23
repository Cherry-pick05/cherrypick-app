import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../widgets/bag_card.dart';
import '../widgets/item_list.dart';
import '../widgets/add_bag_dialog.dart';

class PackingManager extends StatelessWidget {
  final bool showSearch;
  const PackingManager({super.key, this.showSearch = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bags = packingProvider.bags;

        // 가방이 하나도 없을 때: 빈 상태 + 추가 버튼
        if (bags.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.luggage, size: 48),
                  const SizedBox(height: 12),
                  const Text('아직 가방이 없어요'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddBagDialog(),
                      );
                    },
                    child: const Text('가방 추가'),
                  ),
                ],
              ),
            ),
          );
        }

        // 가방이 1개 이상일 때
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔎 본문 검색창 표시 여부 (상단 AppBar에서 이미 쓰면 false로 숨김)
              if (showSearch) ...[
                const _SearchBar(),
                const SizedBox(height: 24),
              ],

              const _BagOverview(),
              const SizedBox(height: 24),
              const _BagTabs(),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    // 가방 카드와 어울리는 중립 테두리 컬러
    final neutralBorder = scheme.outline.withOpacity(0.6);
    final neutralBorderFocused = scheme.outline;

    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return TextField(
          decoration: InputDecoration(
            hintText: '물건 검색...',
            hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withOpacity(0.12),
            prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorderFocused, width: 1), // ← 핑크 X
            ),
          ),
          cursorColor: textColor.withOpacity(0.8),
          onChanged: packingProvider.setSearchQuery,
        );
      },
    );
  }
}

class _BagOverview extends StatelessWidget {
  const _BagOverview();

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bags = packingProvider.bags;
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bags.length + 1, // +1 = 가방 추가 카드
            itemBuilder: (context, index) {
              if (index == bags.length) {
                return const _AddBagCard();
              }
              final bag = bags[index];
              return BagCard(
                bag: bag,
                isSelected: packingProvider.selectedBag == bag.id,
                onTap: () {
                  // 프로바이더 선택 갱신
                  packingProvider.setSelectedBag(bag.id);

                  // 탭 인덱스도 동기화
                  final controller = DefaultTabController.of(context);
                  if (controller.length == bags.length) {
                    controller.index = index;
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _AddBagCard extends StatelessWidget {
  const _AddBagCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          showDialog(context: context, builder: (_) => const AddBagDialog());
        },
        borderRadius: BorderRadius.circular(12),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                '가방 추가',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BagTabs extends StatelessWidget {
  const _BagTabs();

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bags = packingProvider.bags;

        // DefaultTabController 없으면 렌더하지 않음
        final controller = DefaultTabController.maybeOf(context);
        if (controller == null) return const SizedBox.shrink();

        // Provider의 selectedBag과 TabController 인덱스를 동기화
        final selectedId = packingProvider.selectedBag;
        int selectedIndex = 0;
        final idx = bags.indexWhere((b) => b.id == selectedId);
        if (idx >= 0) selectedIndex = idx;
      
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.index != selectedIndex && controller.length == bags.length) {
            controller.index = selectedIndex;
          }
        });

        return Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: [for (final bag in bags) Tab(text: bag.name)],
              onTap: (index) => packingProvider.setSelectedBag(bags[index].id),
            ),
            const SizedBox(height: 16),
            // TabBarView는 고정 높이가 필요
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [for (final bag in bags) ItemList(bagId: bag.id)],
              ),
            ),
          ],
        );
      },
    );
  }
}
