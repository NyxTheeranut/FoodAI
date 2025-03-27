import 'package:flutter/material.dart';
import 'package:recipe_app/pages/ingredients_page.dart';
import 'package:recipe_app/pages/recipes_page.dart';
import 'package:recipe_app/pages/recipes_detail.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/pages/login_page.dart';
import 'dart:ui';

class NutrientResultPage extends StatefulWidget {
  final List<dynamic> recipes;

  const NutrientResultPage({Key? key, required this.recipes}) : super(key: key);

  @override
  _NutrientResultPageState createState() => _NutrientResultPageState();
}

class _NutrientResultPageState extends State<NutrientResultPage> {
  final ApiService apiService = ApiService();
  Map<int, bool> favoriteStates = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteStates();
  }

  Future<void> _loadFavoriteStates() async {
    try {
      final favorites = await apiService.fetchFavorites();
      setState(() {
        favoriteStates = {
          for (var favorite in favorites) int.parse(favorite['recipe_id'].toString()): true
        };
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<bool> _checkLoginStatus() async {
    final token = await apiService.getToken();
    return token != null;
  }

  Future<void> toggleFavorite(int recipeId, String recipeTitle, String imageUrl) async {
    final isLoggedIn = await _checkLoginStatus();
    if (!isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    try {
      bool newFavoriteState;
      if (favoriteStates[recipeId] ?? false) {
        newFavoriteState = await apiService.removeFavorite(recipeId);
      } else {
        newFavoriteState = await apiService.addFavorite(recipeId, recipeTitle, imageUrl);
      }
      setState(() {
        favoriteStates[recipeId] = newFavoriteState;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling favorite: $e')),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Login Required'),
        content: const Text('Please log in to favorite recipes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Text(
                    'Nutrition Results',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: widget.recipes.isEmpty
                  ? Center(
                      child: Text(
                        'No recipes found!',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      itemCount: widget.recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = widget.recipes[index];
                        final recipeId = recipe['id'] as int;
                        final isFavorite = favoriteStates[recipeId] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailPage(
                                    recipeId: recipeId,
                                    userIngredients: [], // No user ingredients for nutrient search
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.grey[200]!.withOpacity(0.5),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          recipe['image'] ?? 'https://via.placeholder.com/312x231',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    recipe['title'] ?? 'Unknown Recipe',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    isFavorite ? Icons.star : Icons.star_border,
                                                    color: isFavorite ? Colors.yellow[700] : Colors.grey,
                                                  ),
                                                  onPressed: () => toggleFavorite(
                                                    recipeId,
                                                    recipe['title'] ?? 'Unknown Recipe',
                                                    recipe['image'] ?? 'https://via.placeholder.com/312x231',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Calories: ${recipe['calories']?.toStringAsFixed(0) ?? 'N/A'} kcal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Protein: ${recipe['protein']?.toStringAsFixed(0) ?? 'N/A'} g',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Fat: ${recipe['fat']?.toStringAsFixed(0) ?? 'N/A'} g',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Carbs: ${recipe['carbs']?.toStringAsFixed(0) ?? 'N/A'} g',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: 2,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey[500],
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Ingredients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'Recipes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_dining),
                label: 'Nutrition',
              ),
            ],
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const IngredientsPage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipesPage()),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}