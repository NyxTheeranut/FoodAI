@extends('layouts.app')

@section('content')
    <div class="bg-gradient-to-r from-[#aad7d4] to-[#69a6a2] rounded-lg shadow-lg p-8 max-w-4xl mx-auto">
        <h1 class="text-2xl font-bold mb-4 text-white" style="font-family: 'Playwrite IN', sans-serif;">My Favorite Recipes
        </h1>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8 mt-6">
            @foreach ($favorites as $favorite)
                <div class="favorite-item relative bg-white border rounded-lg shadow-lg overflow-hidden transform hover:scale-105 transition duration-300 hover:shadow-2xl"
                    data-recipe-id="{{ $favorite->recipe_id }}">

                    <img src="{{ $favorite->recipe_image }}" alt="{{ $favorite->recipe_title }}"
                        class="w-full h-48 object-cover rounded-t-lg">

                    {{-- Favorite Button (Always Yellow) --}}
                    <button class="favorite-btn absolute top-2 right-2 text-xl text-yellow-400 transition duration-200"
                        data-recipe-id="{{ $favorite->recipe_id }}">
                        <i class="fa fa-star"></i> <!-- Star icon -->
                    </button>

                    <div class="p-6">
                        <h3 class="text-xl font-semibold text-teal-600">{{ $favorite->recipe_title }}</h3>
                        <a href="{{ route('recipe.show', ['id' => $favorite->recipe_id]) }}"
                            class="inline-block mt-4 text-teal-600 hover:underline font-medium">View Recipe</a>
                    </div>
                </div>
            @endforeach
        </div>
    </div>
@endsection

{{-- Include SweetAlert2 --}}
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const favoriteButtons = document.querySelectorAll('.favorite-btn');

        favoriteButtons.forEach(button => {
            button.addEventListener('click', function() {
                const recipeId = button.getAttribute('data-recipe-id');
                const recipeCard = button.closest('.favorite-item'); // Get the recipe container

                Swal.fire({
                    title: 'Remove from Favorites?',
                    text: "Are you sure you want to remove this recipe from your favorites?",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#d33',
                    cancelButtonColor: '#3085d6',
                    confirmButtonText: 'Yes, remove it!',
                    cancelButtonText: 'Cancel'
                }).then((result) => {
                    if (result.isConfirmed) {
                        fetch(`{{ url('/favorites') }}/${recipeId}`, {
                                method: 'DELETE',
                                headers: {
                                    'Content-Type': 'application/json',
                                    'Accept': 'application/json',
                                    'X-CSRF-TOKEN': document.querySelector(
                                        'meta[name="csrf-token"]').getAttribute(
                                        'content')
                                }
                            })
                            .then(response => response.json())
                            .then(data => {
                                if (data.success) {
                                    Swal.fire({
                                        icon: 'success',
                                        title: 'Removed!',
                                        text: 'The recipe has been removed from your favorites.',
                                        confirmButtonColor: '#3085d6'
                                    });

                                    // Smoothly fade out and remove the recipe card
                                    recipeCard.style.transition =
                                        'opacity 0.5s, transform 0.5s';
                                    recipeCard.style.opacity = '0';
                                    recipeCard.style.transform = 'scale(0.9)';

                                    setTimeout(() => {
                                        recipeCard.remove();
                                    }, 500); // Remove after animation
                                } else {
                                    Swal.fire({
                                        icon: 'error',
                                        title: 'Error!',
                                        text: data.message ||
                                            'Something went wrong.',
                                        confirmButtonColor: '#d33'
                                    });
                                }
                            })
                            .catch(error => console.error('Fetch Error:', error));
                    }
                });
            });
        });
    });
</script>
