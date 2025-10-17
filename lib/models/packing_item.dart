
class PackingItem {
  final String id;
  final String name;
  final String category;
  final bool packed;
  final String bagId;
  final String? location;
  final String? weight;
  final String? notes;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.packed,
    required this.bagId,
    this.location,
    this.weight,
    this.notes,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? packed,
    String? bagId,
    String? location,
    String? weight,
    String? notes,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      packed: packed ?? this.packed,
      bagId: bagId ?? this.bagId,
      location: location ?? this.location,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'packed': packed,
      'bagId': bagId,
      'location': location,
      'weight': weight,
      'notes': notes,
    };
  }

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      packed: json['packed'],
      bagId: json['bagId'],
      location: json['location'],
      weight: json['weight'],
      notes: json['notes'],
    );
  }
}

class Bag {
  final String id;
  final String name;
  final String type;
  final String color;
  final List<PackingItem> items;

  Bag({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.items,
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
      items: (json['items'] as List)
          .map((item) => PackingItem.fromJson(item))
          .toList(),
    );
  }
}
