import 'packing_item.dart';

class Bag {
  final String id;
  final String name;
  final String type; // 'carry-on', 'checked', 'personal'
  final String color;
  final List<PackingItem> items;

  Bag({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.items = const [],
  });

  Bag copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    List<PackingItem>? items,
  }) {
    return Bag(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Bag.fromJson(Map<String, dynamic> json) {
    return Bag(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      color: json['color'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => PackingItem.fromJson(item))
          .toList() ?? [],
    );
  }
}
