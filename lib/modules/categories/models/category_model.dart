class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String color;
  final String icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.color = '#10B981',
    this.icon = 'tag',
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    String? icon,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      type: json['type']?.toString().toLowerCase() ?? 'expense',
      color: json['color']?.toString() ?? '#10B981',
      icon: json['icon']?.toString() ?? 'tag',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'color': color,
    'icon': icon,
  };
}
