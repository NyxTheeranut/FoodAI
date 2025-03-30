<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\RecipeController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisteredUserController;
use App\Http\Controllers\SettingsController;

Route::middleware(['auth:sanctum'])->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/recipes', [RecipeController::class, 'index']);
Route::post('/recipes/find-by-ingredients', [RecipeController::class, 'findByIngredients']);
Route::get('/recipes/{id}', [RecipeController::class, 'show']);
Route::post('/recipes/find-by-nutrients', [RecipeController::class, 'findByNutrients']);
Route::get('/recipes/nutrients/{id}', [RecipeController::class, 'showByNutrients']);
Route::post('/recipes/search-by-name', [RecipeController::class, 'searchByName']);

Route::post('/login', [LoginController::class, 'login']);
Route::post('/register', [RegisteredUserController::class, 'store']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites', [FavoriteController::class, 'store']);
    Route::delete('/favorites/{id}', [FavoriteController::class, 'destroy']);
    
    // Settings routes
    Route::post('/settings/change-password', [SettingsController::class, 'changePassword']);
    Route::post('/settings/delete-account', [SettingsController::class, 'deleteAccount']);
});