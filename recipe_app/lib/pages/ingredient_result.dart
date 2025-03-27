import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import 'recipes_detail.dart';
import 'login_page.dart';
import 'dart:ui';

class IngredientResultPage extends StatefulWidget {
  final List<String> ingredients;
  final String? dishType;

  const IngredientResultPage({Key? key, required this.ingredients, this.dishType}) : super(key: key);

  @override
  _IngredientResultPageState createState() => _IngredientResultPageState();
}

class _IngredientResultPageState extends State<IngredientResultPage> {
  final ApiService apiService = ApiService();
  List<Recipe> _allRecipes = [];
  int _offset = 0;
  int _limit = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Map<int, bool> favoriteStates = {};
  Set<int> _seenRecipeIds = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _loadFavoriteStates();

    // Add a listener to the scroll controller to detect when the user reaches the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreRecipes();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchRecipes() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      print('Fetching recipes with offset: $_offset, limit: $_limit');
    });

    try {
      final newRecipes = await apiService.fetchRecipes(
        widget.ingredients,
        dishType: widget.dishType,
        limit: _limit,
        offset: _offset,
      );
      print('Received ${newRecipes.length} new recipes');
      setState(() {
        final uniqueRecipes = newRecipes.where((recipe) => _seenRecipeIds.add(recipe.id)).toList();
        _allRecipes.addAll(uniqueRecipes);
        _isLoadingMore = false;
        if (uniqueRecipes.isEmpty) {
          _hasMore = false;
          print('No more unique recipes to load. Offset: $_offset');
        } else {
          _offset += _limit;
          print('More recipes available. New offset: $_offset');
        }
      });
    } catch (error) {
      setState(() {
        _isLoadingMore = false;
      });
      print('Error fetching recipes: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipes: $error')),
      );
    }
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

  void _loadMoreRecipes() {
    if (!_isLoadingMore && _hasMore) {
      _fetchRecipes();
    }
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
                    'Ingredient Results',
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
              child: _allRecipes.isEmpty && _isLoadingMore
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _allRecipes.isEmpty
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
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          itemCount: _allRecipes.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _allRecipes.length) {
                              return const Center(child: CircularProgressIndicator(color: Colors.blue));
                            }

                            final recipe = _allRecipes[index];
                            final isFavorite = favoriteStates[recipe.id] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecipeDetailPage(
                                        recipeId: recipe.id,
                                        userIngredients: widget.ingredients,
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
                                              recipe.image,
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
                                                        recipe.title,
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
                                                      onPressed: () => toggleFavorite(recipe.id, recipe.title, recipe.image),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Used Ingredients: ${recipe.usedIngredientCount}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  'Missing Ingredients: ${recipe.missingIngredientCount}',
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
    );
  }
}