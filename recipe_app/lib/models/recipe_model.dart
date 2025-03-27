class Recipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missingIngredientCount;
  final List<Map<String, dynamic>>? usedIngredients;
  final List<Map<String, dynamic>>? missingIngredients;
  final List<Map<String, dynamic>>? unusedIngredients;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missingIngredientCount,
    this.usedIngredients,
    this.missingIngredients,
    this.unusedIngredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String? ?? 'https://via.placeholder.com/312x231',
      usedIngredientCount: (json['usedIngredients'] as List?)?.length ?? 0,
      missingIngredientCount: (json['missedIngredients'] as List?)?.length ?? 0,
      usedIngredients: (json['usedIngredients'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item))
          .toList(),
      missingIngredients: (json['missedIngredients'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item))
          .toList(),
      unusedIngredients: (json['unusedIngredients'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }
}