import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../pages/recipes_detail.dart';
import 'dart:ui';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _favoritesFuture;
  bool _isSelectionMode = false;
  Map<int, bool> _selectedItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _apiService.fetchFavorites();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode(int initialRecipeId) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (_isSelectionMode) {
        _selectedItems[initialRecipeId] = true;
      } else {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(int recipeId) {
    setState(() {
      _selectedItems[recipeId] = !(_selectedItems[recipeId] ?? false);
    });
  }

  Future<void> _removeSelectedFavorites() async {
    final selectedIds = _selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected to remove')),
      );
      return;
    }

    int successCount = 0;
    List<String> failedRemovals = [];

    for (var id in selectedIds) {
      try {
        final response = await _apiService.removeFavorite(id);
        print('Remove Favorite Response for ID $id: $response'); // Debug log
        successCount++;
        // Remove the item from the selection map
        setState(() {
          _selectedItems.remove(id);
        });
      } catch (e) {
        print('Error removing favorite ID $id: $e'); // Debug log
        failedRemovals.add('Recipe ID $id: $e');
      }
    }

    // Refresh the favorites list
    setState(() {
      _favoritesFuture = _apiService.fetchFavorites();
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });

    // Show a summary of the operation
    String message = 'Removed $successCount favorite(s).';
    if (failedRemovals.isNotEmpty) {
      message += '\nFailed to remove ${failedRemovals.length} item(s):\n${failedRemovals.join('\n')}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<dynamic> _filterFavorites(List<dynamic> favorites) {
    if (_searchQuery.isEmpty) return favorites;
    return favorites
        .where((favorite) =>
            (favorite['recipe_title'] ?? '').toLowerCase().contains(_searchQuery))
        .toList();
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
              child: Column(
                children: [
                  Row(
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
                        'My Favorites',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (_isSelectionMode)
                        GestureDetector(
                          onTap: _removeSelectedFavorites,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: const Icon(
                              Icons.delete,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.grey[200]!.withOpacity(0.5),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search favorites...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.blue),
                          ),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blue));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No favorites found.', style: TextStyle(color: Colors.grey[600])));
                  }

                  final favorites = _filterFavorites(snapshot.data!);
                  if (favorites.isEmpty) {
                    return Center(child: Text('No matching favorites found.', style: TextStyle(color: Colors.grey[600])));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      final imageUrl = favorite['recipe_image']?.isNotEmpty == true
                          ? favorite['recipe_image']
                          : 'https://via.placeholder.com/80';
                      final recipeId = favorite['recipe_id'];
                      final isSelected = _selectedItems[recipeId] ?? false;
                      return GestureDetector(
                        onTap: _isSelectionMode
                            ? () => _toggleItemSelection(recipeId)
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailPage(
                                      recipeId: recipeId,
                                      userIngredients: [],
                                    ),
                                  ),
                                );
                              },
                        onLongPress: () => _toggleSelectionMode(recipeId),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                                child: Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        favorite['recipe_title'] ?? 'Untitled',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) => _toggleItemSelection(recipeId),
                                    activeColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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