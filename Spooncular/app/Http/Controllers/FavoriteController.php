<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FavoriteController extends Controller
{
    // Fetch the user's favorites as JSON
    public function index()
    {
        $favorites = Auth::user()->favorites;
        // return view('favorites.index', compact('favorites'));
        return response()->json($favorites); //for API
    }

    // Add or remove a favorite recipe
    public function store(Request $request)
    {
        if (!Auth::check()) {
            return response()->json(['success' => false, 'message' => 'Please log in first.'], 401);
        }

        $validated = $request->validate([
            'recipe_id' => 'required|string',
            'recipe_title' => 'required|string',
            'recipe_image' => 'nullable|string',
            'view_recipe_url' => 'required|string',
        ]);

        // Check if the recipe is already in favorites
        $existingFavorite = Favorite::where('user_id', Auth::id())
            ->where('recipe_id', $validated['recipe_id'])
            ->first();

        if ($existingFavorite) {
            // If the recipe is already a favorite, remove it
            $existingFavorite->delete();
            return response()->json(['success' => true, 'message' => 'Recipe removed from favorites.', 'favorited' => false]);
        }

        // Otherwise, add the recipe as a favorite
        $favorite = Favorite::create([
            'user_id' => Auth::id(),
            'recipe_id' => $validated['recipe_id'],
            'recipe_title' => $validated['recipe_title'],
            'recipe_image' => $validated['recipe_image'],
            'view_recipe_url' => $validated['view_recipe_url'],
        ]);

        return response()->json(['success' => true, 'message' => 'Recipe added to favorites!', 'favorited' => true]);
    }

    // Remove a favorite recipe
    public function destroy($id)
    {
        $favorite = Favorite::where('user_id', Auth::id())
            ->where('recipe_id', $id)
            ->first();

        if ($favorite) {
            $favorite->delete();
            return response()->json(['success' => true, 'message' => 'Recipe removed from favorites.', 'favorited' => false]);
        }

        return response()->json(['success' => false, 'message' => 'Favorite not found.'], 404);
    }
}
