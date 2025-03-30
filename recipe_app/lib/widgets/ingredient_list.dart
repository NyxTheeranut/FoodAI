// import 'package:flutter/material.dart';
// import '../services/api_service.dart';

// class RecipeDetailPage extends StatefulWidget {
//   final int recipeId;
//   final List<String>? userIngredients;

//   const RecipeDetailPage({Key? key, required this.recipeId, this.userIngredients}) : super(key: key);

//   @override
//   _RecipeDetailPageState createState() => _RecipeDetailPageState();
// }

// class _RecipeDetailPageState extends State<RecipeDetailPage> {
//   late Future<Map<String, dynamic>> recipeData;
//   bool isFavorite = false;
//   final ApiService apiService = ApiService();

//   @override
//   void initState() {
//     super.initState();
//     recipeData = apiService.fetchRecipeDetails(widget.recipeId, widget.userIngredients);
//     checkFavoriteStatus();
//   }

//   Future<void> checkFavoriteStatus() async {
//     try {
//       final favorites = await apiService.fetchFavorites();
//       setState(() {
//         isFavorite = favorites.any((fav) => fav['recipe_id'] == widget.recipeId);
//       });
//     } catch (e) {
//       print('Error checking favorite status: $e');
//     }
//   }

//   Future<void> toggleFavorite() async {
//     try {
//       if (isFavorite) {
//         await apiService.removeFavorite(widget.recipeId);
//       } else {
//         await apiService.addFavorite(widget.recipeId);
//       }
//       setState(() {
//         isFavorite = !isFavorite;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error toggling favorite: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Recipe Details"),
//         actions: [
//           IconButton(
//             icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
//             color: isFavorite ? Colors.red : null,
//             onPressed: toggleFavorite,
//           ),
//         ],
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: recipeData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData) {
//             return const Center(child: Text('No data available.'));
//           }

//           final recipe = snapshot.data!['recipe'];
//           final matchingIngredients = snapshot.data!['matchingIngredients'] as List<dynamic>;
//           final formattedInstructions = snapshot.data!['formattedInstructions'] as String;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: Image.network(
//                     recipe['image'] ?? '',
//                     width: double.infinity,
//                     height: 200,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   recipe['title'] ?? 'Unknown Recipe',
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text("Ingredients:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Column(
//                   children: matchingIngredients.map((ingredient) {
//                     return ListTile(
//                       leading: Icon(
//                         ingredient['matched'] ? Icons.check_circle : Icons.cancel,
//                         color: ingredient['matched'] ? Colors.green : Colors.red,
//                       ),
//                       title: Text(ingredient['ingredient']),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text("Instructions:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Text(
//                   formattedInstructions.replaceAll('<br>', '\n'),
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }