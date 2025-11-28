/// Represents a clothing item in the user's personal wardrobe
class UserWardrobeItem {
  final String id;
  final String name;
  final String category;
  final String styleType; // casual, formal, semi_formal
  final String imagePath; // Local file path
  final String? color;
  final String? notes;
  final DateTime addedAt;

  const UserWardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.styleType,
    required this.imagePath,
    this.color,
    this.notes,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'styleType': styleType,
        'imagePath': imagePath,
        'color': color,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
      };

  factory UserWardrobeItem.fromJson(Map<String, dynamic> json) {
    return UserWardrobeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      styleType: json['styleType'] as String,
      imagePath: json['imagePath'] as String,
      color: json['color'] as String?,
      notes: json['notes'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  UserWardrobeItem copyWith({
    String? id,
    String? name,
    String? category,
    String? styleType,
    String? imagePath,
    String? color,
    String? notes,
    DateTime? addedAt,
  }) {
    return UserWardrobeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      styleType: styleType ?? this.styleType,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
