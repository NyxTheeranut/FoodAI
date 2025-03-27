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
  bool _isFavorited = false;
  String? _userEmail;
  String? _errorMessage;

  // State for interactive instructions
  bool _isStepByStepMode = false;
  int _currentStepIndex = 0;
  List<String> _instructionSteps = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkLoginStatus();
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
          setState(() {
            _userEmail = userData['email'];
          });
          _checkIfFavorited();
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

  Future<void> _checkIfFavorited() async {
    if (_userEmail == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _apiService.getToken()}',
        },
      );
      if (response.statusCode == 200) {
        final favorites = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isFavorited =
                favorites.any((fav) => fav['recipe_id'] == widget.recipeId);
          });
        }
      }
    } catch (e) {
      print('Error checking favorites: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userEmail == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login first to favorite this recipe.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception(
            'Authentication token is missing. Please log in again.');
      }

      if (_isFavorited) {
        final response = await http.delete(
          Uri.parse('${ApiService.baseUrl}/favorites/${widget.recipeId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
            'Unfavorite Response: ${response.statusCode} - ${response.body}'); // Debug log
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _isFavorited = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recipe removed from favorites')),
            );
            // Recheck favorited status to ensure sync with server
            await _checkIfFavorited();
          }
        } else {
          throw Exception(
              'Failed to remove favorite: ${response.statusCode} - ${response.body}');
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/favorites'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'recipe_id': widget.recipeId,
            'title': _recipeDetails?['recipe']?['title'] ?? 'Unknown Recipe',
            'image': _recipeDetails?['recipe']?['image'] ?? '',
          }),
        );
        print(
            'Favorite Response: ${response.statusCode} - ${response.body}'); // Debug log
        if (response.statusCode == 201) {
          if (mounted) {
            setState(() {
              _isFavorited = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recipe added to favorites')),
            );
            // Recheck favorited status to ensure sync with server
            await _checkIfFavorited();
          }
        } else {
          throw Exception(
              'Failed to add favorite: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Error in _toggleFavorite: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _parseInstructions(String instructions) {
    return instructions.replaceAll('<br>', '\n');
  }

  List<String> _parseSteps(String instructions) {
    List<String> steps = [];
    String currentStep = '';
    List<String> lines = instructions.split('\n');

    // Regular expression to detect numbered steps (e.g., "1.", "2.", etc.)
    RegExp stepPattern = RegExp(r'^\d+\.\s');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (stepPattern.hasMatch(line)) {
        // If we have accumulated a step, add it to the list
        if (currentStep.isNotEmpty) {
          steps.add(currentStep.trim());
          currentStep = '';
        }
        currentStep = line;
      } else {
        // Append the line to the current step with a space
        currentStep += ' $line';
      }
    }

    // Add the last step if it exists
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
        _isStepByStepMode = false; // Exit step-by-step mode when done
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
                      ...(_recipeDetails!['matchingIngredients'] as List)
                          .map<Widget>((ingredient) {
                        bool isMatched = ingredient['matched'] ?? false;
                        bool showSymbols = widget.userIngredients
                            .isNotEmpty; // Only show symbols if searching by ingredients

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Combine checkmark and ingredient name into a single Text widget
                              Flexible(
                                child: Text(
                                  (showSymbols
                                          ? (isMatched ? '✔ ' : '✘ ')
                                          : '') +
                                      (ingredient['ingredient']?.toString() ??
                                          'Unknown'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: showSymbols
                                        ? (isMatched
                                            ? Colors.green
                                            : Colors.red)
                                        : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '(${ingredient['metricAmount']?.toString() ?? '0'} ${ingredient['metricUnit']?.toString() ?? ''})',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: showSymbols
                                      ? (isMatched ? Colors.green : Colors.red)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()
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
                        // Show all steps initially
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
                        // Step-by-step mode
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
