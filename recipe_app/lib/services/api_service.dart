import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/api'; 



  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Recipe>> fetchRecipes(List<String> ingredients,
      {String? dishType, int limit = 10, int offset = 0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipes/find-by-ingredients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ingredients': ingredients,
        'limit': limit,
        'offset': offset,
        'ranking': 1,
        'ignorePantry': true,
        if (dishType != null) 'dishType': dishType,
      }),
    );
    print('Fetch recipes response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Recipe.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch recipes: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchRecipeDetails(
      int recipeId, List<String>? userIngredients) async {
    final Uri uri = Uri.parse('$baseUrl/recipes/$recipeId').replace(
      queryParameters: {'ingredients': userIngredients?.join(',') ?? ''},
    );
    final response =
        await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch recipe details: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchFavorites() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch favorites: ${response.body}');
    }
  }

  Future<bool> addFavorite(
      int recipeId, String recipeTitle, String imageUrl) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'recipe_id': recipeId.toString(),
        'recipe_title': recipeTitle,
        'recipe_image': imageUrl,
        'view_recipe_url': imageUrl,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorited'] ?? true;
    } else {
      throw Exception('Failed to add favorite: ${response.body}');
    }
  }

  Future<bool> removeFavorite(int recipeId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$recipeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorited'] ?? false;
    } else {
      throw Exception('Failed to remove favorite: ${response.body}');
    }
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await _saveToken(token);
      return token;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map && responseBody.containsKey('token')) {
        await _saveToken(responseBody['token']);
      } else {
        await login(email, password);
      }
    } else if (response.statusCode == 422) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          'Validation failed: ${errorBody['message']} - ${errorBody['errors'] ?? 'Unknown error'}');
    } else {
      throw Exception(
          'Registration failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<List<dynamic>> findRecipesByNutrients({
    double minCalories = 0,
    double maxCalories = 10000,
    double minProtein = 0,
    double maxProtein = 1000,
    double minFat = 0,
    double maxFat = 1000,
    double minCarbs = 0,
    double maxCarbs = 1000,
    int limit = 10,
    int offset = 0,
    String? dishType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipes/find-by-nutrients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'minCalories': minCalories,
        'maxCalories': maxCalories,
        'minProtein': minProtein,
        'maxProtein': maxProtein,
        'minFat': minFat,
        'maxFat': maxFat,
        'minCarbs': minCarbs,
        'maxCarbs': maxCarbs,
        'limit': limit,
        'offset': offset,
        if (dishType != null) 'dishType': dishType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to find recipes by nutrients: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchRecipeByNutrients(
      int recipeId, String? title, String? image) async {
    final Uri uri = Uri.parse('$baseUrl/recipes/nutrients/$recipeId').replace(
      queryParameters: {
        if (title != null) 'title': title,
        if (image != null) 'image': image,
      },
    );
    final response =
        await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to fetch recipe details by nutrients: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> searchRecipesByName({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipes/search-by-name'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'limit': limit,
        'offset': offset,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to search recipes by name: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Not logged in');

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user: ${response.body}');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) throw Exception('Not logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/settings/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  Future<bool> deleteAccount(String password) async {
    final token = await getToken();
    if (token == null) throw Exception('Not logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/settings/delete-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      await logout();
      return true;
    } else {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }
}