<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\RecipeController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\Auth\AuthenticatedSessionController;

// Display the login form
Route::get('login', [LoginController::class, 'showLoginForm'])->name('login');

// Handle login form submission
Route::post('/login', [AuthenticatedSessionController::class, 'store'])->name('login');

// Display the register form
Route::get('register', [RegisterController::class, 'showRegistrationForm'])->name('register');

// Handle register form submission
Route::post('/register', [RegisterController::class, 'register'])->name('register');

// Handle logout
Route::post('logout', [LoginController::class, 'logout'])->name('logout');

Route::get('/', [RecipeController::class, 'index'])->name('recipes.index');
Route::get('/recipe/{id}', [RecipeController::class, 'show'])->name('recipe.show');
Route::get('/recipes/findByIngredients', [RecipeController::class, 'findByIngredients'])->name('findByIngredients');
Route::get('/recipes', [RecipeController::class, 'index']);
Route::get('/find-by-nutrients', [RecipeController::class, 'findByNutrients'])->name('findByNutrients');

Route::middleware('auth')->group(function () {
    Route::get('/favorites', [FavoriteController::class, 'index'])->name('favorites.index');
    Route::post('/favorites', [FavoriteController::class, 'store'])->name('favorites.store');
    Route::delete('/favorites/{id}', [FavoriteController::class, 'destroy'])->name('favorites.destroy'); 
});




// require __DIR__.'/auth.php';
