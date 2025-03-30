<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;

class RecipeController extends Controller
{
    public function index()
    {
        return view('recipes.index'); // Ensure the view path is correct
    }

    public function findByNutrients(Request $request)
    {
        // Extract nutrient constraints and other parameters from the request
        $minCalories = $request->input('minCalories', 0); // Default to 0 if not provided
        $maxCalories = $request->input('maxCalories', 10000); // Default to a high value
        $minProtein = $request->input('minProtein', 0);
        $maxProtein = $request->input('maxProtein', 1000);
        $minFat = $request->input('minFat', 0);
        $maxFat = $request->input('maxFat', 1000);
        $minCarbs = $request->input('minCarbs', 0);
        $maxCarbs = $request->input('maxCarbs', 1000);
        $limit = $request->input('limit', 10); // Default to 10
        $offset = $request->input('offset', 0); // Default offset is 0
        $dishType = $request->input('dishType'); // Optional: "dessert", "main course", etc.

        // Validate the request parameters
        $request->validate([
            'minCalories' => 'nullable|numeric|min:0',
            'maxCalories' => 'nullable|numeric|min:0',
            'minProtein' => 'nullable|numeric|min:0',
            'maxProtein' => 'nullable|numeric|min:0',
            'minFat' => 'nullable|numeric|min:0',
            'maxFat' => 'nullable|numeric|min:0',
            'minCarbs' => 'nullable|numeric|min:0',
            'maxCarbs' => 'nullable|numeric|min:0',
            'limit' => 'integer|min:1|max:50',
            'offset' => 'integer|min:0',
            'dishType' => 'nullable|string',
        ]);

        // Ensure at least one nutrient constraint is provided
        if (
            $minCalories == 0 && $maxCalories == 10000 &&
            $minProtein == 0 && $maxProtein == 1000 &&
            $minFat == 0 && $maxFat == 1000 &&
            $minCarbs == 0 && $maxCarbs == 1000
        ) {
            return response()->json(['error' => 'At least one nutrient constraint must be provided'], 400);
        }

        // Get the Spoonacular API key
        $apiKey = env('SPOONACULAR_API_KEY');
        if (!$apiKey) {
            return response()->json(['error' => 'Spoonacular API key is not configured'], 500);
        }

        // Use the complexSearch endpoint
        $url = 'https://api.spoonacular.com/recipes/complexSearch';

        // Build the query parameters
        $params = [
            'apiKey' => $apiKey,
            'number' => 20, // Max limit per Spoonacular request
            'offset' => 0, // We'll handle pagination manually
            'addRecipeInformation' => true, // Include dishTypes and nutrition in the response
            'addRecipeNutrition' => true, // Include nutritional information
            // Nutrient constraints
            'minCalories' => $minCalories,
            'maxCalories' => $maxCalories,
            'minProtein' => $minProtein,
            'maxProtein' => $maxProtein,
            'minFat' => $minFat,
            'maxFat' => $maxFat,
            'minCarbs' => $minCarbs,
            'maxCarbs' => $maxCarbs,
        ];

        // Add dishType (type) if provided
        if ($dishType) {
            $params['type'] = $dishType; // Filter by dish type (e.g., "main course", "dessert")
        }

        // Make the API request
        $response = Http::get($url, $params);

        if ($response->failed()) {
            return response()->json([
                'error' => 'Failed to fetch recipes from Spoonacular',
                'details' => 'Status: ' . $response->status() . ', Body: ' . $response->body(),
            ], 502);
        }

        $data = $response->json();
        $allRecipes = $data['results'] ?? [];

        // Apply offset and limit to the filtered results
        $totalRecipes = count($allRecipes);
        $start = min($offset, $totalRecipes);
        $end = min($start + $limit, $totalRecipes);
        $pagedRecipes = array_slice($allRecipes, $start, $end);

        // Format the response to match the structure of findByIngredients
        $formattedRecipes = array_map(function ($recipe) {
            return [
                'id' => $recipe['id'],
                'title' => $recipe['title'],
                'image' => $recipe['image'] ?? 'https://via.placeholder.com/312x231',
                'calories' => $recipe['nutrition']['nutrients'][0]['amount'] ?? 0, // Assuming calories is the first nutrient
                'protein' => $recipe['nutrition']['nutrients'][1]['amount'] ?? 0, // Assuming protein is the second nutrient
                'fat' => $recipe['nutrition']['nutrients'][2]['amount'] ?? 0, // Assuming fat is the third nutrient
                'carbs' => $recipe['nutrition']['nutrients'][3]['amount'] ?? 0, // Assuming carbs is the fourth nutrient
            ];
        }, $pagedRecipes);

        return response()->json($formattedRecipes);
    }

    public function showByNutrients($id, Request $request)
    {
        $apiKey = env('SPOONACULAR_API_KEY');
        $url = "https://api.spoonacular.com/recipes/{$id}/nutritionWidget.json?apiKey={$apiKey}";

        $response = Http::get($url);

        if ($response->successful()) {
            $nutrition = $response->json();

            // Extract essential nutrients (protein, carbs, fat)
            $nutrients = [
                'protein' => null,
                'carbs' => null,
                'fat' => null,
            ];

            if (isset($nutrition['nutrients']) && is_array($nutrition['nutrients'])) {
                foreach ($nutrition['nutrients'] as $nutrient) {
                    switch (strtolower($nutrient['name'])) {
                        case 'protein':
                            $nutrients['protein'] = $nutrient['amount'] . 'g';
                            break;
                        case 'carbohydrates':
                            $nutrients['carbs'] = $nutrient['amount'] . 'g';
                            break;
                        case 'fat':
                            $nutrients['fat'] = $nutrient['amount'] . 'g';
                            break;
                    }
                }
            }

            return response()->json([
                'id' => $id,
                'title' => $request->query('title', 'Unknown Recipe'),
                'image' => $request->query('image', 'https://via.placeholder.com/312x231'),
                'protein' => $nutrients['protein'],
                'carbs' => $nutrients['carbs'],
                'fat' => $nutrients['fat'],
            ], 200); // Use 200 OK for successful response
        } else {
            return response()->json([
                'error' => 'Recipe not found',
                'details' => 'Spoonacular API returned status ' . $response->status(),
            ], 404);
        }
    }

    public function findByIngredients(Request $request)
    {
        $ingredients = $request->input('ingredients', []);
        $limit = $request->input('limit', 10); // Default to 10, max slice size
        $offset = $request->input('offset', 0); // Default offset is 0
        $ranking = $request->input('ranking', 1);
        $ignorePantry = $request->input('ignorePantry', true);
        $dishType = $request->input('dishType'); // Example: "dessert" or "main course"

        $request->validate([
            'ingredients' => 'required|array|min:1',
            'ingredients.*' => 'string|max:255',
            'limit' => 'integer|min:1|max:50',
            'offset' => 'integer|min:0',
            'ranking' => 'integer|in:1,2',
            'ignorePantry' => 'boolean',
            'dishType' => 'nullable|string',
        ]);

        $apiKey = env('SPOONACULAR_API_KEY');
        if (!$apiKey) {
            return response()->json(['error' => 'Spoonacular API key is not configured'], 500);
        }

        $ingredientString = implode(',', $ingredients);

        // Use the findByIngredients endpoint
        $url = 'https://api.spoonacular.com/recipes/findByIngredients';

        $params = [
            'apiKey' => $apiKey,
            'ingredients' => $ingredientString,
            'number' => 20, // Max limit per Spoonacular request
            'offset' => 0, // We'll handle pagination manually
            'ranking' => $ranking, // 1: maximize used ingredients, 2: minimize missing ingredients
            'ignorePantry' => $ignorePantry,
        ];

        $response = Http::get($url, $params);

        if ($response->failed()) {
            return response()->json([
                'error' => 'Failed to fetch recipes from Spoonacular',
                'details' => 'Status: ' . $response->status() . ', Body: ' . $response->body(),
            ], 502);
        }

        $allRecipes = $response->json();

        // Filter by dishType if provided (since findByIngredients doesn't support type directly)
        if ($dishType) {
            $allRecipes = array_filter($allRecipes, function ($recipe) use ($dishType) {
                // Fetch recipe information to get dishTypes
                $recipeId = $recipe['id'];
                $apiKey = env('SPOONACULAR_API_KEY');
                $infoUrl = "https://api.spoonacular.com/recipes/$recipeId/information";
                $infoResponse = Http::get($infoUrl, [
                    'apiKey' => $apiKey,
                    'includeNutrition' => false,
                ]);

                if ($infoResponse->failed()) {
                    return false; // Skip if we can't fetch the info
                }

                $recipeInfo = $infoResponse->json();
                $dishTypes = $recipeInfo['dishTypes'] ?? [];
                return in_array(strtolower($dishType), array_map('strtolower', $dishTypes));
            });

            // Reindex the array after filtering
            $allRecipes = array_values($allRecipes);
        }

        // Apply offset and limit to the filtered results
        $totalRecipes = count($allRecipes);
        $start = min($offset, $totalRecipes);
        $end = min($start + $limit, $totalRecipes);
        $pagedRecipes = array_slice($allRecipes, $start, $end);

        // Format the response to match the expected structure
        $formattedRecipes = array_map(function ($recipe) {
            return [
                'id' => $recipe['id'],
                'title' => $recipe['title'],
                'image' => $recipe['image'] ?? 'https://via.placeholder.com/312x231',
                'usedIngredientCount' => $recipe['usedIngredientCount'] ?? 0,
                'missingIngredientCount' => $recipe['missedIngredientCount'] ?? 0,
                'usedIngredients' => $recipe['usedIngredients'] ?? [],
                'missedIngredients' => $recipe['missedIngredients'] ?? [],
                'unusedIngredients' => $recipe['unusedIngredients'] ?? [],
            ];
        }, $pagedRecipes);

        return response()->json($formattedRecipes);
    }

    public function show($id, Request $request)
    {
        $apiKey = env('SPOONACULAR_API_KEY');
        $url = "https://api.spoonacular.com/recipes/{$id}/information?apiKey={$apiKey}";

        $response = Http::get($url);

        if ($response->successful()) {
            $recipe = $response->json();

            // Get ingredients from the query string
            $userIngredients = explode(',', $request->query('ingredients', ''));

            // Process matching ingredients with metric amounts
            $matchingIngredients = $this->getMatchingIngredients($userIngredients, $recipe['extendedIngredients']);
            $instructions = $recipe['instructions'] ?? null;
            // Process instructions
            $formattedInstructions = $this->formatInstructions($instructions);
            // Return for Flutter API response
            return response()->json([
                'recipe' => $recipe,
                'userIngredients' => $userIngredients,
                'matchingIngredients' => $matchingIngredients,
                'formattedInstructions' => $formattedInstructions,
            ]);
        } else {
            return response()->json([
                'error' => 'Recipe not found',
                'details' => 'Spoonacular API returned status ' . $response->status(),
            ], 404);
        }
    }

    private function getMatchingIngredients($userIngredients, $recipeIngredients)
    {
        $matches = [];

        foreach ($recipeIngredients as $ingredient) {
            $ingredientName = strtolower($ingredient['name']);
            $metricAmount = $ingredient['measures']['metric']['amount'] ?? 0;
            $metricUnit = $ingredient['measures']['metric']['unitShort'] ?? '';

            // Check if any user ingredient matches or partially matches the recipe ingredient
            $matched = false;
            foreach ($userIngredients as $userIngredient) {
                if (stripos($ingredientName, strtolower($userIngredient)) !== false) {
                    $matched = true;
                    break;
                }
            }

            $matches[] = [
                'ingredient' => $ingredient['name'],
                'matched' => $matched,
                'metricAmount' => $metricAmount,
                'metricUnit' => $metricUnit,
            ];
        }

        return $matches;
    }

    private function formatInstructions($instructions)
    {
        // Check if instructions are null, empty, or not meaningful
        if (is_null($instructions) || (is_string($instructions) && trim($instructions) === '') || (is_array($instructions) && empty($instructions))) {
            return ''; // Return empty string if no valid instructions
        }

        // Ensure $instructions is a string (in case it's an array)
        if (is_array($instructions)) {
            $instructions = implode(' ', $instructions); // Join array into a string
        }

        // Remove HTML tags except for basic formatting
        $instructions = strip_tags($instructions, '<p><br>');

        // Check if the instructions already contain a numbered sequence (e.g., "1.", "2.", etc.)
        $hasNumberedSequence = preg_match('/^\d+\.\s/', $instructions) || preg_match('/\n\d+\.\s/', $instructions);

        if ($hasNumberedSequence) {
            // If instructions already have a numbered sequence, just clean up and return
            $steps = array_filter(array_map('trim', explode('<br>', $instructions)), 'strlen');
            return implode('<br>', $steps);
        }

        // Split the instructions by period followed by a space (for unnumbered instructions)
        $steps = preg_split('/(?<=\.)\s+/', $instructions);

        // Trim extra spaces and filter out empty steps
        $steps = array_filter(array_map('trim', $steps), 'strlen');

        // If no valid steps remain, return empty string
        if (empty($steps)) {
            return '';
        }

        // Add sequence numbers to the steps
        $stepsWithNumbers = array_map(function ($step, $index) {
            return ($index + 1) . '. ' . $step; // Prefix each step with its sequence number
        }, $steps, array_keys($steps));

        // Return the steps with a line break
        return implode('<br>', $stepsWithNumbers);
    }

    public function searchByName(Request $request)
    {
        $query = $request->input('query');
        $limit = $request->input('limit', 10);
        $offset = $request->input('offset', 0);

        // Validate the request parameters
        $request->validate([
            'query' => 'required|string|min:1',
            'limit' => 'integer|min:1|max:50',
            'offset' => 'integer|min:0',
        ]);

        $apiKey = env('SPOONACULAR_API_KEY');
        if (!$apiKey) {
            return response()->json(['error' => 'Spoonacular API key is not configured'], 500);
        }

        $url = 'https://api.spoonacular.com/recipes/complexSearch';

        $params = [
            'apiKey' => $apiKey,
            'query' => $query,
            'number' => 20, // Fetch more than the limit to handle pagination
            'offset' => 0,
            'addRecipeInformation' => true,
            'addRecipeNutrition' => true,
        ];

        $response = Http::get($url, $params);

        if ($response->failed()) {
            return response()->json([
                'error' => 'Failed to fetch recipes from Spoonacular',
                'details' => 'Status: ' . $response->status() . ', Body: ' . $response->body(),
            ], 502);
        }

        $data = $response->json();
        $allRecipes = $data['results'] ?? [];

        $totalRecipes = count($allRecipes);
        $start = min($offset, $totalRecipes);
        $end = min($start + $limit, $totalRecipes);
        $pagedRecipes = array_slice($allRecipes, $start, $end);

        $formattedRecipes = array_map(function ($recipe) {
            $calories = 0;
            $protein = 0;
            $fat = 0;
            $carbs = 0;

            // Safely parse nutrients by name
            if (isset($recipe['nutrition']['nutrients'])) {
                foreach ($recipe['nutrition']['nutrients'] as $nutrient) {
                    $name = $nutrient['name'] ?? '';
                    $amount = $nutrient['amount'] ?? 0;
                    if (strtolower($name) === 'calories') $calories = $amount;
                    if (strtolower($name) === 'protein') $protein = $amount;
                    if (strtolower($name) === 'fat') $fat = $amount;
                    if (strtolower($name) === 'carbohydrates') $carbs = $amount;
                }
            }

            return [
                'id' => $recipe['id'],
                'title' => $recipe['title'],
                'image' => $recipe['image'] ?? 'https://via.placeholder.com/312x231',
                'calories' => $calories,
                'protein' => $protein,
                'fat' => $fat,
                'carbs' => $carbs,
            ];
        }, $pagedRecipes);

        return response()->json($formattedRecipes);
    }
}
