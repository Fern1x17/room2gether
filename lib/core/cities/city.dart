class City {
  const City({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.aliases = const [],
    required this.isActive,
  });

  final String id;
  final String name;
  final String normalizedName;
  final List<String> aliases;
  final bool isActive;

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      aliases: (map['aliases'] as List<dynamic>? ?? const []).cast<String>(),
      isActive: map['is_active'] as bool,
    );
  }
}
