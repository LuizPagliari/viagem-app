class Destination {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  bool isVisited;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isVisited = false,
  });

  // Converter para JSON para salvar em SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'isVisited': isVisited,
    };
  }

  // Converter de JSON para objeto
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isVisited: json['isVisited'],
    );
  }
}