import 'package:flutter/material.dart';
import '../models/packing_item.dart' as item;
import '../models/bag.dart' as bag;

// Remove duplicate class definitions and use models instead
// PackingItem class is now imported from models/packing_item.dart

// Bag class is now imported from models/bag.dart

class PackingProvider extends ChangeNotifier {
  final List<bag.Bag> _bags = [
    bag.Bag(
      id: "carry-on",
      name: "기내용 캐리어",
      type: "carry-on",
      color: "blue",
      items: [
        item.PackingItem(
          id: "1",
          name: "여권",
          category: "서류",
          packed: true,
          bagId: "carry-on",
          location: "앞주머니",
        ),
        item.PackingItem(
          id: "2",
          name: "충전기",
          category: "전자기기",
          packed: true,
          bagId: "carry-on",
          location: "메인칸",
        ),
        item.PackingItem(
          id: "3",
          name: "화장품",
          category: "세면용품",
          packed: false,
          bagId: "carry-on",
          location: "지퍼백",
        ),
        item.PackingItem(
          id: "4",
          name: "약품",
          category: "의료용품",
          packed: true,
          bagId: "carry-on",
          location: "앞주머니",
        ),
      ],
    ),
    bag.Bag(
      id: "checked",
      name: "위탁용 캐리어",
      type: "checked",
      color: "green",
      items: [
        item.PackingItem(
          id: "5",
          name: "옷가지",
          category: "의류",
          packed: true,
          bagId: "checked",
          location: "메인칸",
        ),
        item.PackingItem(
          id: "6",
          name: "신발",
          category: "신발",
          packed: true,
          bagId: "checked",
          location: "신발칸",
        ),
        item.PackingItem(
          id: "7",
          name: "헤어드라이어",
          category: "전자기기",
          packed: false,
          bagId: "checked",
          location: "메인칸",
        ),
        item.PackingItem(
          id: "8",
          name: "선물",
          category: "기타",
          packed: false,
          bagId: "checked",
          location: "메인칸",
        ),
      ],
    ),
    bag.Bag(
      id: "backpack",
      name: "백팩",
      type: "personal",
      color: "purple",
      items: [
        item.PackingItem(
          id: "9",
          name: "노트북",
          category: "전자기기",
          packed: true,
          bagId: "backpack",
          location: "노트북칸",
        ),
        item.PackingItem(
          id: "10",
          name: "책",
          category: "도서",
          packed: false,
          bagId: "backpack",
          location: "메인칸",
        ),
        item.PackingItem(
          id: "11",
          name: "간식",
          category: "음식",
          packed: true,
          bagId: "backpack",
          location: "앞주머니",
        ),
      ],
    ),
  ];

  String _selectedBag = "carry-on";
  String _searchQuery = "";

  List<bag.Bag> get bags => _bags;
  String get selectedBag => _selectedBag;
  String get searchQuery => _searchQuery;

  void setSelectedBag(String bagId) {
    _selectedBag = bagId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleItemPacked(String bagId, String itemId) {
    final bagIndex = _bags.indexWhere((bag) => bag.id == bagId);
    if (bagIndex != -1) {
      final itemIndex = _bags[bagIndex].items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final item = _bags[bagIndex].items[itemIndex];
        final updatedItem = item.copyWith(packed: !item.packed);
        _bags[bagIndex] = _bags[bagIndex].copyWith(
          items: List.from(_bags[bagIndex].items)
            ..[itemIndex] = updatedItem,
        );
        notifyListeners();
      }
    }
  }

  void addItem(item.PackingItem item) {
    final bagIndex = _bags.indexWhere((bag) => bag.id == item.bagId);
    if (bagIndex != -1) {
      _bags[bagIndex] = _bags[bagIndex].copyWith(
        items: List.from(_bags[bagIndex].items)..add(item),
      );
      notifyListeners();
    }
  }

  void removeItem(String bagId, String itemId) {
    final bagIndex = _bags.indexWhere((bag) => bag.id == bagId);
    if (bagIndex != -1) {
      _bags[bagIndex] = _bags[bagIndex].copyWith(
        items: _bags[bagIndex].items.where((item) => item.id != itemId).toList(),
      );
      notifyListeners();
    }
  }

  void addBag(bag.Bag bag) {
    _bags.add(bag);
    notifyListeners();
  }

  List<item.PackingItem> getFilteredItems(String bagId) {
    final bag = _bags.firstWhere((bag) => bag.id == bagId);
    if (_searchQuery.isEmpty) return bag.items;
    
    return bag.items.where((item) =>
      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (item.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  int getPackingProgress(String bagId) {
    final bag = _bags.firstWhere((bag) => bag.id == bagId);
    if (bag.items.isEmpty) return 0;
    
    final packedItems = bag.items.where((item) => item.packed).length;
    return ((packedItems / bag.items.length) * 100).round();
  }
}
