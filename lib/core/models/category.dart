class PropertyCategory {
  final String id;
  final String name;
  final String iconName;
  final DateTime createdAt;

  PropertyCategory({
    required this.id,
    required this.name,
    this.iconName = 'home_work_rounded',
    required this.createdAt,
  });

  factory PropertyCategory.fromJson(Map<String, dynamic> json) {
    return PropertyCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String? ?? 'home_work_rounded',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'icon_name': iconName,
    };
  }
}
