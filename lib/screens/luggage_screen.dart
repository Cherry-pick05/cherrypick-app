import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/packing_manager.dart';
import '../providers/packing_provider.dart';

class LuggageScreen extends StatefulWidget {
  const LuggageScreen({super.key});

  @override
  State<LuggageScreen> createState() => _LuggageScreenState();
}

class _LuggageScreenState extends State<LuggageScreen> {
  String _selectedTrip = '오사카 여행';

  @override
  Widget build(BuildContext context) {
    final bagCount = context.watch<PackingProvider>().bags.length;
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    // 가방 카드 선택 시의 테두리/배경과 어울리는 중립 톤
    final neutralBorder = scheme.outline.withOpacity(0.6); // 일반
    final neutralBorderFocused = scheme.outline;           // 포커스

    PreferredSizeWidget topBar() {
      final scheme = Theme.of(context).colorScheme;
      final textColor = scheme.onSurface;

      return PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀을 중앙 정렬하기 위해 Row → Stack 변경
                SizedBox(
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 가운데: cherry pick
                      const Text(
                        'cherry pick',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      // 왼쪽: 오사카 여행 토글 (고스트 스타일)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => _showTripSelector(context),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedTrip,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      // 오른쪽은 비워두되 중앙 정렬에 영향 없도록 투명 박스
                      const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 28, height: 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 검색창
                TextField(
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
                      borderSide: BorderSide(color: scheme.outline.withOpacity(0.6), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outline.withOpacity(0.6), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outline, width: 1),
                    ),
                  ),
                  cursorColor: textColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (bagCount == 0) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: topBar(),
        body: const PackingManager(showSearch: false),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      );
    }

    // 가방 1개 이상
    return DefaultTabController(
      key: ValueKey(bagCount),
      length: bagCount,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: topBar(),
        body: const PackingManager(showSearch: false),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      ),
    );
  }

  void _showTripSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final destinations = ['오사카 여행', '서울 여행', '도쿄 여행', '파리 여행'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (c, i) {
              final dest = destinations[i];
              final selected = dest == _selectedTrip;
              return ListTile(
                title: Text(
                  dest,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: selected ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  setState(() => _selectedTrip = dest);
                  Navigator.pop(context);
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: destinations.length,
          ),
        );
      },
    );
  }
}
