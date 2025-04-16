import 'package:flutter/material.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;
  final List<String> userIngredients;

  const RecipeDetailPage({
    Key? key,
    required this.recipeId,
    required this.userIngredients,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = true;
  bool _isFavorited = false; // Local state for UI
  String? _userEmail;
  String? _errorMessage;
  bool _isTogglingFavorite = false; // Prevent rapid clicks

  // State for interactive instructions
  bool _isStepByStepMode = false;
  int _currentStepIndex = 0;
  List<String> _instructionSteps = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails(); // Fetch recipe data first
    _initializePage(); // Then check login and favorite status
  }

  // Combined initialization logic
  Future<void> _initializePage() async {
    await _checkLoginStatus();
    // Only refresh favorite status if logged in
    if (_userEmail != null) {
      await _refreshFavoriteStatus();
    }
  }


  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/user'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _userEmail = userData['email'];
            });
            // Don't call _checkIfFavorited here, handled by _initializePage
          }
        } else if (response.statusCode == 401) {
          // Handle token expiration/invalidation if needed
          print('User fetch failed: Token invalid (401)');
          // Optionally clear token and prompt login
        }
      } catch (e) {
        print('Error fetching user: $e');
      }
    }
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/recipes/${widget.recipeId}?ingredients=${widget.userIngredients.join(',')}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Recipe Details Response: $data'); // Debug log
        setState(() {
          _recipeDetails = data;
          _isLoading = false;
          // Parse instructions into steps
          if (_recipeDetails?['formattedInstructions'] != null &&
              _recipeDetails!['formattedInstructions'].isNotEmpty) {
            String instructions =
                _parseInstructions(_recipeDetails!['formattedInstructions']);
            _instructionSteps = _parseSteps(instructions);
          }
        });
      } else {
        throw Exception(
            'Failed to load recipe details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe details: $e'); // Debug log
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load recipe details: $e';
      });
    }
  }

  // Renamed and modified from _checkIfFavorited to align with results page
  Future<void> _refreshFavoriteStatus() async {
    if (_userEmail == null) {
      print('Cannot refresh favorite status: User not logged in.');
      return; // Don't proceed if not logged in
    }
    print('Refreshing favorite status for recipe ${widget.recipeId}...');
    try {
      // Use ApiService consistently
      final favorites = await _apiService.fetchFavorites();
      if (mounted) {
        final bool isNowFavorited = favorites.any((fav) =>
            fav['recipe_id'] != null &&
            int.tryParse(fav['recipe_id'].toString()) == widget.recipeId);
        setState(() {
          _isFavorited = isNowFavorited;
        });
        print('Favorite status refreshed. Is favorited: $_isFavorited');
      }
    } catch (e, stackTrace) {
      print('Error refreshing favorite status: $e');
      print(stackTrace);
      // Optionally show a snackbar, but might be annoying on load
    }
  }


  // Rewritten _toggleFavorite using ApiService and refresh logic
  Future<void> _toggleFavorite() async {
     // Prevent multiple taps while processing
    if (_isTogglingFavorite) return;

    final isLoggedIn = await _apiService.getToken() != null;
    if (!isLoggedIn) {
      _showLoginPrompt(); // Use a separate method for the dialog
      return;
    }

    // Ensure recipe details are loaded before trying to favorite
    if (_recipeDetails == null || _recipeDetails!['recipe'] == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Recipe details not loaded yet.')),
       );
       return;
    }

    setState(() { _isTogglingFavorite = true; });

    try {
      // --- Refresh state before toggling (like in results page) ---
      await _refreshFavoriteStatus();
      // -----------------------------------------------------------

      final bool isCurrentlyFavorite = _isFavorited; // Use the refreshed state
      final String recipeTitle = _recipeDetails!['recipe']?['title'] ?? 'Unknown Recipe';
      final String imageUrl = _recipeDetails!['recipe']?['image'] ?? ''; // Use placeholder if needed

      print('Attempting to toggle favorite. Currently favorite: $isCurrentlyFavorite');

      bool success; // Use a single variable for the result
      if (isCurrentlyFavorite) {
        success = await _apiService.removeFavorite(widget.recipeId);
        // ApiService's removeFavorite should ideally return false if successful
        // Let's assume it returns true on success for now based on addFavorite pattern
        // We'll update the state based on the intended final state
        if (success) { // Assuming true means successful removal
           if (mounted) setState(() { _isFavorited = false; });
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Recipe removed from favorites')),
           );
        } else {
           throw Exception('API indicated failure removing favorite.');
        }

      } else {
        success = await _apiService.addFavorite(widget.recipeId, recipeTitle, imageUrl);
         // ApiService's addFavorite should ideally return true if successful
        if (success) {
           if (mounted) setState(() { _isFavorited = true; });
            ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Recipe added to favorites')),
           );
        } else {
           throw Exception('API indicated failure adding favorite.');
        }
      }

    } catch (e, stackTrace) {
      print('Error toggling favorite for recipe ${widget.recipeId}: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite status. Error: ${e.runtimeType}')),
        );
        // Optionally re-refresh status on error to ensure consistency
        await _refreshFavoriteStatus();
      }
    } finally {
       if (mounted) {
         setState(() { _isTogglingFavorite = false; });
       }
    }
  }

  // Extracted Login Prompt Dialog
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
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) {
                  // After login page is popped, re-check login status and favorites
                  _initializePage();
                });
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


  String _parseInstructions(String instructions) {
    return instructions.replaceAll('<br>', '\n');
  }

  List<String> _parseSteps(String instructions) {
    List<String> steps = [];
    String currentStep = '';
    List<String> lines = instructions.split('\n');

    RegExp stepPattern = RegExp(r'^\d+\.\s');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (stepPattern.hasMatch(line)) {
        if (currentStep.isNotEmpty) {
          steps.add(currentStep.trim());
          currentStep = '';
        }
        currentStep = line;
      } else {
        currentStep += ' $line';
      }
    }

    if (currentStep.isNotEmpty) {
      steps.add(currentStep.trim());
    }

    return steps;
  }

  void _startStepByStepMode() {
    setState(() {
      _isStepByStepMode = true;
      _currentStepIndex = 0;
    });
  }

  void _nextStep() {
    setState(() {
      if (_currentStepIndex < _instructionSteps.length - 1) {
        _currentStepIndex++;
      } else {
        _isStepByStepMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchRecipeDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    _recipeDetails?['recipe']?['image'] ??
                        'https://via.placeholder.com/312x231',
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
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
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Icon(
                          _isFavorited ? Icons.star : Icons.star_border,
                          size: 28,
                          color: _isFavorited
                              ? Colors.yellow[700]
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipeDetails?['recipe']?['title'] ?? 'Unknown Recipe',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_recipeDetails?['matchingIngredients'] != null &&
                        (_recipeDetails!['matchingIngredients'] as List)
                            .isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height *
                              0.5, // Limit to half screen height
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable scrolling in ListView
                          children:
                              (_recipeDetails!['matchingIngredients'] as List)
                                  .map<Widget>((ingredient) {
                            bool isMatched = ingredient['matched'] ?? false;
                            bool showSymbols = widget.userIngredients
                                .isNotEmpty; // Only show symbols if searching by ingredients

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Wrap(
                                      children: [
                                        Text(
                                          showSymbols
                                              ? (isMatched ? '✔ ' : '✘ ')
                                              : '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: showSymbols
                                                ? (isMatched
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          ingredient['ingredient']?.toString() ??
                                              'Unknown',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: showSymbols
                                                ? (isMatched
                                                    ? Colors.green
                                                    : Colors.red)
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8), // Small gap between name and amount
                                  Text(
                                    '(${ingredient['metricAmount']?.toString() ?? '0'} ${ingredient['metricUnit']?.toString() ?? ''})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: showSymbols
                                          ? (isMatched
                                              ? Colors.green
                                              : Colors.red)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      const Text(
                        'No ingredients available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_instructionSteps.isNotEmpty) ...[
                      if (!_isStepByStepMode) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _instructionSteps
                              .asMap()
                              .entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startStepByStepMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Begin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${_currentStepIndex + 1} of ${_instructionSteps.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _instructionSteps[_currentStepIndex],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  _currentStepIndex ==
                                          _instructionSteps.length - 1
                                      ? 'Done'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else
                      const Text(
                        'No instructions available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
