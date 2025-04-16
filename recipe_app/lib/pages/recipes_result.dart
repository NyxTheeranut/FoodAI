import 'package:flutter/material.dart';
import 'package:recipe_app/pages/ingredients_page.dart';
import 'package:recipe_app/pages/nutrition_page.dart';
import 'package:recipe_app/pages/recipes_detail.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/pages/login_page.dart';
import 'dart:ui';

class RecipeSearchResultPage extends StatefulWidget {
  final String query;

  const RecipeSearchResultPage({Key? key, required this.query}) : super(key: key);

  @override
  _RecipeSearchResultPageState createState() => _RecipeSearchResultPageState();
}

class _RecipeSearchResultPageState extends State<RecipeSearchResultPage> {
  final ApiService apiService = ApiService();
  List<dynamic> _allRecipes = [];
  int _offset = 0;
  int _limit = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Map<int, bool> favoriteStates = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _loadFavoriteStates();

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
      print('Fetching recipes with query: ${widget.query}, offset: $_offset, limit: $_limit');
    });

    try {
      final newRecipes = await apiService.searchRecipesByName(
        query: widget.query,
        limit: _limit,
        offset: _offset,
      );
      print('Received ${newRecipes.length} new recipes');
      setState(() {
        _allRecipes.addAll(newRecipes);
        _isLoadingMore = false;
        if (newRecipes.isEmpty) {
          _hasMore = false;
          print('No more recipes to load. Offset: $_offset');
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

    // --- Diagnostic Step: Refresh favorite states before toggling ---
    // This ensures we have the latest status before making the add/remove call.
    // Consider removing this if it doesn't solve the issue, for performance.
    print('Refreshing favorite states before toggling recipe $recipeId...');
    await _loadFavoriteStates();
    print('Favorite states refreshed.');
    // -------------------------------------------------------------

    try {
      // Check the refreshed state
      final bool isCurrentlyFavorite = favoriteStates[recipeId] ?? false;
      print('Attempting to toggle favorite. Currently favorite: $isCurrentlyFavorite');

      bool newFavoriteState;
      if (isCurrentlyFavorite) { // Use the refreshed state
        newFavoriteState = await apiService.removeFavorite(recipeId);
      } else {
        newFavoriteState = await apiService.addFavorite(recipeId, recipeTitle, imageUrl);
      }
      setState(() {
        // Update state only if the API call was successful and returned a boolean
        if (newFavoriteState is bool) {
           favoriteStates[recipeId] = newFavoriteState;
        } else {
          // Handle cases where the API might not return the expected boolean
          // Optionally, refetch favorites to ensure consistency
           print('API did not return expected boolean for favorite toggle. Refetching favorites.');
           _loadFavoriteStates(); // Refetch to be safe
        }
      });
    } catch (e, stackTrace) {
      // Log detailed error to console
      print('Error toggling favorite for recipe $recipeId: $e');
      print(stackTrace);

      // Show a more informative SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status. Please try again. Error: ${e.runtimeType}')),
      );
      // Optionally, revert optimistic UI update if you implement that later
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
                    'Search Results',
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
                                        userIngredients: [], // No user ingredients for name search
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
                                            child: Row(
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
            currentIndex: 1,
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
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NutritionPage()),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
