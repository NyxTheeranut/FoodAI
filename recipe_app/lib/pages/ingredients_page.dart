import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'ingredient_result.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'favorites_page.dart';
import 'nutrition_page.dart';
import 'recipes_page.dart';
import 'settings_page.dart';
import 'package:recipe_app/util/no_animation_page_route.dart';

class IngredientsPage extends StatefulWidget {
  const IngredientsPage({super.key});

  @override
  State<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  final List<String> _ingredients = [];
  final TextEditingController _controller = TextEditingController();
  String? _hoveredIngredient;
  bool _isProfilePanelOpen = false;
  final ApiService _apiService = ApiService();
  String? _userEmail;
  final FocusNode _focusNode = FocusNode();
  String? _selectedDishType;
  final List<String> _dishTypes = ['main course', 'dessert', 'side dish'];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
        }
      } catch (e) {
        // Handle error silently for now
      }
    } else {
      setState(() {
        _userEmail = null;
      });
    }
  }

  void _addIngredient() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_controller.text.trim());
        _controller.clear();
      });
      _focusNode.requestFocus();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  void _toggleProfilePanel() {
    setState(() {
      _isProfilePanelOpen = !_isProfilePanelOpen;
    });
  }

  Future<void> _logout() async {
    await _apiService.logout();
    setState(() {
      _userEmail = null;
    });
    _toggleProfilePanel();
  }

  void _searchRecipes() {
    if (_ingredients.isNotEmpty) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => IngredientResultPage(
            ingredients: _ingredients,
            dishType: _selectedDishType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Ingredients',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleProfilePanel,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    color: Colors.grey[200]!.withOpacity(0.5),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _controller,
                                            focusNode: _focusNode,
                                            decoration: InputDecoration(
                                              hintText: 'Enter Ingredient',
                                              hintStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            style: const TextStyle(
                                                color: Colors.black87),
                                            onSubmitted: (_) =>
                                                _addIngredient(),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: GestureDetector(
                                            onTap: _addIngredient,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.grey[200]!.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 1),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDishType,
                                      hint: const Text('Dish Type'),
                                      items: _dishTypes.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Text(value),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedDishType = newValue;
                                        });
                                      },
                                      style:
                                          const TextStyle(color: Colors.black87),
                                      dropdownColor: Colors.white,
                                      iconEnabledColor: Colors.blue,
                                      borderRadius: BorderRadius.circular(15), // Rounded corners for dropdown menu
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _ingredients.isEmpty
                              ? Center(
                                  child: Text(
                                    'No ingredients yet!',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _ingredients.map((ingredient) {
                                    return Chip(
                                      label: Text(
                                        ingredient,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      backgroundColor: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      deleteIcon: Icon(
                                        Icons.cancel,
                                        color: _hoveredIngredient == ingredient
                                            ? Colors.redAccent
                                            : Colors.grey[400],
                                        size: 20,
                                      ),
                                      onDeleted: () =>
                                          _removeIngredient(ingredient),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _ingredients.isEmpty ? null : _searchRecipes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Find Recipes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            right: _isProfilePanelOpen ? 0 : -280,
            width: 280,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      _userEmail ?? 'Guest',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _toggleProfilePanel,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 24,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _userEmail == null
                                ? [
                                    _buildProfileButton('Login', () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                const LoginPage()),
                                      ).then((_) {
                                        _checkLoginStatus();
                                        _toggleProfilePanel();
                                      });
                                    }),
                                    const SizedBox(height: 12),
                                    _buildProfileButton('Register', () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                const RegisterPage()),
                                      ).then((_) {
                                        _checkLoginStatus();
                                        _toggleProfilePanel();
                                      });
                                    }),
                                  ]
                                : [
                                    _buildProfileButton('Favorites', () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                const FavoritesPage()),
                                      );
                                      _toggleProfilePanel();
                                    }),
                                  ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileButton('Settings', () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          const SettingsPage()),
                                ).then((_) {
                                  _checkLoginStatus();
                                  _toggleProfilePanel();
                                });
                              }),
                              const SizedBox(height: 12),
                              if (_userEmail != null)
                                _buildProfileButton('Logout', _logout),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: 0, // Highlight the "Ingredients" tab
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
              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  NoAnimationPageRoute(
                      builder: (context) => const RecipesPage()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  NoAnimationPageRoute(
                      builder: (context) => const NutritionPage()),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(String title, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}