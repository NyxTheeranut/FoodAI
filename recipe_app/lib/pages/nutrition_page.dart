import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/pages/nutrition_result.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/pages/ingredients_page.dart';
import 'package:recipe_app/pages/recipes_page.dart';
import 'package:recipe_app/pages/login_page.dart';
import 'package:recipe_app/pages/register_page.dart';
import 'package:recipe_app/pages/favorites_page.dart';
import 'package:recipe_app/pages/settings_page.dart';
import 'package:recipe_app/util/no_animation_page_route.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  _NutritionPageState createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _minCaloriesController = TextEditingController();
  final _maxCaloriesController = TextEditingController();
  final _minProteinController = TextEditingController();
  final _maxProteinController = TextEditingController();
  final _minFatController = TextEditingController();
  final _maxFatController = TextEditingController();
  final _minCarbsController = TextEditingController();
  final _maxCarbsController = TextEditingController();
  String? _selectedDishType;
  final List<String> _dishTypes = ['main course', 'dessert', 'side dish'];
  final ApiService _apiService = ApiService();
  bool _isProfilePanelOpen = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _minCaloriesController.dispose();
    _maxCaloriesController.dispose();
    _minProteinController.dispose();
    _maxProteinController.dispose();
    _minFatController.dispose();
    _maxFatController.dispose();
    _minCarbsController.dispose();
    _maxCarbsController.dispose();
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

  void _searchRecipes() async {
    try {
      final recipes = await _apiService.findRecipesByNutrients(
        minCalories: double.tryParse(_minCaloriesController.text) ?? 0,
        maxCalories: double.tryParse(_maxCaloriesController.text) ?? 10000,
        minProtein: double.tryParse(_minProteinController.text) ?? 0,
        maxProtein: double.tryParse(_maxProteinController.text) ?? 1000,
        minFat: double.tryParse(_minFatController.text) ?? 0,
        maxFat: double.tryParse(_maxFatController.text) ?? 1000,
        minCarbs: double.tryParse(_minCarbsController.text) ?? 0,
        maxCarbs: double.tryParse(_maxCarbsController.text) ?? 1000,
        dishType: _selectedDishType,
      );

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => NutrientResultPage(recipes: recipes),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                        'Search by Nutrients',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _minCaloriesController, 'Min Calories',
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                  _maxCaloriesController, 'Max Calories',
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _minProteinController, 'Min Protein (g)',
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                  _maxProteinController, 'Max Protein (g)',
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _minFatController, 'Min Fat (g)',
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                  _maxFatController, 'Max Fat (g)',
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _minCarbsController, 'Min Carbs (g)',
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                  _maxCarbsController, 'Max Carbs (g)',
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                  style: const TextStyle(color: Colors.black87),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: Colors.blue,
                                  borderRadius: BorderRadius.circular(15), // Rounded corners for dropdown menu
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _searchRecipes,
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
            currentIndex: 2, // Highlight the "Nutrition" tab
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
                  NoAnimationPageRoute(
                      builder: (context) => const IngredientsPage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  NoAnimationPageRoute(
                      builder: (context) => const RecipesPage()),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.grey[200]!.withOpacity(0.5),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(color: Colors.black87),
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