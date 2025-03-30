// import 'package:flutter/material.dart';
// import '../models/recipe_model.dart';
// import '../pages/recipes_detail.dart';

// class RecipeCard extends StatelessWidget {
//   final Recipe recipe;
//   final List<String>? userIngredients;

//   const RecipeCard({Key? key, required this.recipe, this.userIngredients}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => RecipeDetailPage(
//                 recipeId: recipe.id,
//                 userIngredients: userIngredients,
//               ),
//             ),
//           );
//         },
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 recipe.title,
//                 style: const TextStyle(
//                   fontSize: 18.0,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'Used Ingredients: ${recipe.usedIngredients.join(', ')}',
//                 style: const TextStyle(fontSize: 14.0),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Missing Ingredients: ${recipe.missingIngredients.length}',
//                 style: const TextStyle(fontSize: 14.0),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }