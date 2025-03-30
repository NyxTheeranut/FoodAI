@extends('layouts.app')

@section('title', 'Search Recipes')

@section('content')
    <div class="bg-gradient-to-r from-[#aad7d4] to-[#69a6a2] rounded-lg shadow-lg p-8 max-w-4xl mx-auto">
        <h1 class="text-4xl font-extrabold text-white mb-8 text-center" style="font-family: 'Playwrite IN', sans-serif;">
            Find Recipes</h1>

        <!-- Toggle Button -->
        <div class="mb-6 text-center">
            <button id="toggleSearchType"
                class="px-6 py-3 bg-[#8cbd97] text-white font-bold rounded-full shadow-lg hover:bg-[#5cae6f] transition duration-200">
                Change to Search by Nutrients
            </button>
        </div>

        <!-- Search Forms -->
        <div id="searchForms">
            <!-- Default: Search by Ingredients -->
            <form method="GET" action="{{ route('findByIngredients') }}" class="space-y-6" id="ingredientsForm"
                style="display: block;">
                <h2 class="text-2xl font-extrabold text-white mb-4 text-center">Search by Ingredients</h2>

                <div id="ingredients-container" class="space-y-4">
                    <div class="ingredient-group flex items-center gap-4">
                        <input type="text" name="ingredients[]"
                            class="block w-full rounded-md border-gray-300 shadow-sm focus:border-teal-500 focus:ring-teal-500 sm:text-sm py-3 px-4"
                            placeholder="Add an ingredient" required>
                        <button type="button"
                            class="remove-ingredient px-3 py-2 bg-red-500 text-white rounded-md shadow-lg hover:bg-red-600 transition duration-200">
                            Remove
                        </button>
                    </div>
                </div>
                <button type="button" id="add-ingredient"
                    class="mt-2 px-6 py-3 bg-[#8cbd97] text-white font-bold rounded-full shadow-lg hover:bg-[#5cae6f] transition duration-200">
                    + Add Ingredient
                </button>

                <!-- Other fields -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-6">
                    <div>
                        <label for="number" class="block text-sm font-medium text-white">Number of Recipes</label>
                        <input type="number" name="number" id="number"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 pl-2 sm:text-sm h-8"
                            placeholder="5" value="5" min="1" max="100">
                    </div>
                    <div>
                        <label for="ranking" class="block text-sm font-medium text-white">Ranking</label>
                        <select name="ranking" id="ranking"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 sm:text-sm pl-1 h-8 transition duration-200 ease-in-out">
                            <option value="1">Maximize Used Ingredients</option>
                            <option value="2">Minimize Missing Ingredients</option>
                        </select>
                    </div>
                    <div class="hidden">
                        <label for="ignorePantry" class="block text-sm font-medium text-gray-700">Ignore Pantry
                            Items</label>
                        <select name="ignorePantry" id="ignorePantry"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 sm:text-sm pl-1 h-8 transition duration-200 ease-in-out">
                            <option value="1">Yes</option>
                            <option value="0">No</option>
                        </select>
                    </div>
                </div>

                <!-- Dish Type Filter -->
                <div>
                    <label for="dishType" class="block text-sm font-medium text-white">Dish Type</label>
                    <select name="dishType" id="dishType"
                        class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 sm:text-sm pl-1 h-8 transition duration-200 ease-in-out">
                        <option value="">All</option>
                        <option value="main course">Main Course</option>
                        <option value="dessert">Dessert</option>
                        <option value="side dish">Side Dish</option>
                        <!-- Add more options as needed -->
                    </select>
                </div>

                <button type="submit"
                    class="w-full sm:w-auto mt-6 px-6 py-3 bg-[#8cbd97] text-white font-bold rounded-full shadow-lg hover:bg-[#5cae6f] transition duration-200">
                    Search Recipes
                </button>
            </form>

            <!-- Search by Nutrients (Hidden by default) -->
            <form method="GET" action="{{ route('findByNutrients') }}" class="space-y-6" id="nutrientsForm"
                style="display: none;">
                <h2 class="text-2xl font-extrabold text-white mb-4 text-center">Search by Nutrients</h2>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                        <label for="maxProtein" class="block text-sm font-medium text-white">Max Protein (g)</label>
                        <input type="number" name="maxProtein" id="maxProtein"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 pl-2 sm:text-sm h-8"
                            placeholder="e.g., 50" min="0">
                    </div>
                    <div>
                        <label for="maxCarbs" class="block text-sm font-medium text-white">Max Carbs (g)</label>
                        <input type="number" name="maxCarbs" id="maxCarbs"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 pl-2 sm:text-sm h-8"
                            placeholder="e.g., 100" min="0">
                    </div>
                    <div>
                        <label for="maxFat" class="block text-sm font-medium text-white">Max Fat (g)</label>
                        <input type="number" name="maxFat" id="maxFat"
                            class="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-teal-500 focus:ring-2 focus:ring-teal-500 pl-2 sm:text-sm h-8"
                            placeholder="e.g., 30" min="0">
                    </div>
                </div>

                <button type="submit"
                    class="w-full sm:w-auto mt-6 px-6 py-3 bg-[#8cbd97] text-white font-bold rounded-full shadow-lg hover:bg-[#5cae6f] transition duration-200">
                    Search Recipes
                </button>
            </form>
        </div>

        <!-- Display Results -->
        @isset($recipes)
            <h2 class="text-3xl font-extrabold text-white mt-8 mb-4 text-center"
                style="font-family: 'Playwrite IN', sans-serif;">Recipe Results</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8 mt-6">
                @foreach ($recipes as $recipe)
                    @php
                        $isFavorite = in_array($recipe['id'], $favoriteRecipeIds ?? []);
                    @endphp
                    <div
                        class="relative bg-white border rounded-lg shadow-lg overflow-hidden transform hover:scale-105 transition duration-300 hover:shadow-2xl">
                        <!-- Recipe Image -->
                        <img src="{{ $recipe['image'] }}" alt="{{ $recipe['title'] }}"
                            class="w-full h-48 object-cover rounded-t-lg">

                        <!-- Favorite Button -->
                        <button
                            class="favorite-btn absolute top-2 right-2 text-xl transition duration-200 {{ $isFavorite ? 'text-yellow-400' : 'text-gray-500' }}"
                            data-recipe-id="{{ $recipe['id'] }}" data-recipe-title="{{ $recipe['title'] }}"
                            data-recipe-image="{{ $recipe['image'] }}">
                            <i class="fa fa-star"></i> <!-- Star icon -->
                        </button>

                        <div class="p-6">
                            <h3 class="text-xl font-semibold text-teal-600">{{ $recipe['title'] }}</h3>
                            @if (isset($ingredients) && !empty($ingredients))
                                <!-- Ingredient-based results -->
                                <p class="text-sm text-gray-600 mt-2">Used Ingredients:
                                    {{ $recipe['usedIngredientCount'] ?? 0 }}</p>
                                <p class="text-sm text-gray-600">Missed Ingredients:
                                    {{ $recipe['missedIngredientCount'] ?? 0 }}</p>
                            @else
                                <!-- Nutrient-based results -->
                                <p class="text-sm text-gray-600 mt-2">Protein: {{ $recipe['protein'] ?? 'N/A' }}</p>
                                <p class="text-sm text-gray-600">Carbs: {{ $recipe['carbs'] ?? 'N/A' }}</p>
                                <p class="text-sm text-gray-600">Fat: {{ $recipe['fat'] ?? 'N/A' }}</p>
                            @endif

                            <!-- Link to View Recipe -->
                            <a href="{{ route('recipe.show', ['id' => $recipe['id']]) }}?ingredients={{ isset($ingredients) ? implode(',', $ingredients) : '' }}"
                                class="inline-block mt-4 text-teal-600 hover:underline font-medium">
                                View Recipe
                            </a>
                        </div>
                    </div>
                @endforeach
            </div>
        @endisset
    </div>

    <!-- JavaScript -->
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const toggleButton = document.getElementById('toggleSearchType');
            const ingredientsForm = document.getElementById('ingredientsForm');
            const nutrientsForm = document.getElementById('nutrientsForm');
            let isNutrientSearch = false;

            // Toggle between search types
            toggleButton.addEventListener('click', () => {
                isNutrientSearch = !isNutrientSearch;
                if (isNutrientSearch) {
                    ingredientsForm.style.display = 'none';
                    nutrientsForm.style.display = 'block';
                    toggleButton.textContent = 'Change to Search by Ingredients';
                } else {
                    ingredientsForm.style.display = 'block';
                    nutrientsForm.style.display = 'none';
                    toggleButton.textContent = 'Change to Search by Nutrients';
                }
            });

            const ingredientsContainer = document.getElementById('ingredients-container');
            const addIngredientButton = document.getElementById('add-ingredient');

            // Add new ingredient input field
            addIngredientButton.addEventListener('click', () => {
                const ingredientGroup = document.createElement('div');
                ingredientGroup.classList.add('ingredient-group', 'flex', 'items-center', 'gap-4', 'mt-2');
                ingredientGroup.innerHTML = `
                    <input 
                        type="text" 
                        name="ingredients[]" 
                        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-teal-500 focus:ring-teal-500 sm:text-sm py-3 px-4" 
                        placeholder="Enter an ingredient" 
                        required>
                    <button 
                        type="button" 
                        class="remove-ingredient px-3 py-2 bg-red-500 text-white rounded-md shadow-lg hover:bg-red-600 transition duration-200">
                        Remove
                    </button>
                `;
                ingredientsContainer.appendChild(ingredientGroup);
            });

            // Remove an ingredient input field
            ingredientsContainer.addEventListener('click', (event) => {
                if (event.target.classList.contains('remove-ingredient')) {
                    const ingredientGroup = event.target.closest('.ingredient-group');
                    ingredientGroup.remove();
                }
            });

            // Pre-fill ingredients if they exist in the query string
            const urlParams = new URLSearchParams(window.location.search);
            const ingredients = urlParams.getAll('ingredients[]');

            // If there are ingredients in the URL query, add them to the form
            ingredients.forEach(ingredient => {
                const ingredientGroup = document.createElement('div');
                ingredientGroup.classList.add('ingredient-group', 'flex', 'items-center', 'gap-4', 'mt-2');
                ingredientGroup.innerHTML = `
                    <input 
                        type="text" 
                        name="ingredients[]" 
                        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-teal-500 focus:ring-teal-500 sm:text-sm py-3 px-4" 
                        value="${ingredient}" 
                        placeholder="Enter an ingredient" 
                        required>
                    <button 
                        type="button" 
                        class="remove-ingredient px-3 py-2 bg-red-500 text-white rounded-md shadow-lg hover:bg-red-600 transition duration-200">
                        Remove
                    </button>
                `;
                ingredientsContainer.appendChild(ingredientGroup);
            });
        });

        document.addEventListener('DOMContentLoaded', function() {
            const favoriteButtons = document.querySelectorAll('.favorite-btn');

            favoriteButtons.forEach(button => {
                button.addEventListener('click', function(event) {
                    const recipeId = button.getAttribute('data-recipe-id');

                    // Check if the user is logged in
                    if (!{{ auth()->check() ? 'true' : 'false' }}) {
                        alert('Please log in to add to favorites!');
                        return;
                    }

                    const icon = button.querySelector('i');
                    const isCurrentlyFavorited = icon.classList.contains('text-yellow-400');

                    // Construct the "View Recipe" URL
                    const viewRecipeUrl = "{{ route('recipe.show', ['id' => '__recipe_id__']) }}"
                        .replace('__recipe_id__', recipeId);

                    const data = {
                        recipe_id: recipeId,
                        recipe_title: button.getAttribute('data-recipe-title'),
                        recipe_image: button.getAttribute('data-recipe-image'),
                        view_recipe_url: viewRecipeUrl,
                    };

                    // If already favorited, send DELETE request; otherwise, send POST request
                    const method = isCurrentlyFavorited ? 'DELETE' : 'POST';
                    const url = isCurrentlyFavorited ?
                        `{{ url('/favorites') }}/${recipeId}` :
                        "{{ route('favorites.store') }}";

                    fetch(url, {
                            method: method,
                            headers: {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                                'X-CSRF-TOKEN': document.querySelector(
                                    'meta[name="csrf-token"]').getAttribute('content')
                            },
                            body: method === 'POST' ? JSON.stringify(data) : null
                        })
                        .then(response => response.json())
                        .then(data => {
                            if (data.success) {
                                if (data.favorited) {
                                    icon.classList.add('text-yellow-400');
                                    icon.classList.remove('text-gray-500');
                                    // alert('Added to favorites!');
                                } else {
                                    icon.classList.add('text-gray-500');
                                    icon.classList.remove('text-yellow-400');
                                    // alert('Removed from favorites!');
                                }
                            } else {
                                // alert('Error: ' + (data.message || 'Something went wrong.'));
                            }
                        })
                        .catch(error => console.error('Fetch Error:', error));
                });
            });
        });
    </script>
@endsection
