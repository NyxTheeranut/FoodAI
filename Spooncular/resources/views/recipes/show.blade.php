@extends('layouts.app')

@section('title', $recipe['title'])

@section('content')
    <div class="container mx-auto px-6 py-8">
        <!-- Back Button -->
        <div class="mb-8">
            <a href="{{ url()->previous() }}"
                class="inline-flex items-center px-4 py-2 bg-teal-600 text-white text-sm font-medium rounded-full shadow-md hover:bg-teal-700 transition duration-200">
                <svg class="w-4 h-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Back
            </a>
        </div>

        <!-- Recipe Card -->
        <div class="max-w-4xl mx-auto bg-white rounded-lg shadow-xl overflow-hidden">
            <img src="{{ $recipe['image'] }}" alt="{{ $recipe['title'] }}" class="w-full h-64 object-cover rounded-t-lg">

            <div class="p-6">
                <!-- Recipe Title -->
                <h1 class="text-4xl font-extrabold text-teal-600 leading-tight">{{ $recipe['title'] }}</h1>

                <!-- Ingredients Section -->
                <section class="mt-8">
                    <h2 class="text-2xl font-semibold text-gray-800 border-b-2 pb-2">Ingredients</h2>
                    <ul class="grid grid-cols-2 gap-4 list-none mt-4">
                        @foreach ($matchingIngredients as $match)
                            <li class="flex items-center justify-between text-gray-700">
                                <div class="flex items-center">
                                    @if ($match['matched'])
                                        <svg class="w-5 h-5 text-teal-600 mr-2" xmlns="http://www.w3.org/2000/svg"
                                            fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                d="M5 13l4 4L19 7" />
                                        </svg>
                                        <span class="text-teal-600">{{ $match['ingredient'] }}</span>
                                    @else
                                        <svg class="w-5 h-5 text-red-600 mr-2" xmlns="http://www.w3.org/2000/svg"
                                            fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                        <span class="text-red-600">{{ $match['ingredient'] }}</span>
                                    @endif
                                </div>
                                <span class="text-gray-500 text-sm">
                                    {{ number_format($match['metricAmount'], 1) }} {{ $match['metricUnit'] }}
                                </span>
                            </li>
                        @endforeach
                    </ul>
                </section>

                <!-- Instructions Section -->
                <section class="mt-8">
                    <h2 class="text-2xl font-semibold text-gray-800 border-b-2 pb-2">Instructions</h2>
                    <div class="mt-4 text-gray-700 leading-relaxed">
                        {!! $formattedInstructions !!}
                    </div>
                </section>
            </div>
        </div>
    </div>
@endsection
