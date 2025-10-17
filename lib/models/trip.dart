
class Trip {
  final String id;
  final String name;
  final String destination;
  final String startDate;
  final String duration;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.duration,
  });

  Trip copyWith({
    String? id,
    String? name,
    String? destination,
    String? startDate,
    String? duration,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate,
      'duration': duration,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      destination: json['destination'],
      startDate: json['startDate'],
      duration: json['duration'],
    );
  }
}
