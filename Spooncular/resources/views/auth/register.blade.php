<!-- resources/views/auth/register.blade.php -->
@extends('layouts.app')

@section('content')
<div class="bg-gradient-to-r from-[#aad7d4] to-[#69a6a2] rounded-lg shadow-lg p-8 max-w-4xl mx-auto">
    <form action="{{ route('register') }}" method="POST">
        @csrf
        <div class="mb-4">
            <label for="name" class="block text-gray-700">Name</label>
            <input type="text" id="name" name="name" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
        </div>
        <div class="mb-4">
            <label for="email" class="block text-gray-700">Email</label>
            <input type="email" id="email" name="email" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
        </div>
        <div class="mb-4">
            <label for="password" class="block text-gray-700">Password</label>
            <input type="password" id="password" name="password" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
        </div>
        <div class="mb-4">
            <label for="password_confirmation" class="block text-gray-700">Confirm Password</label>
            <input type="password" id="password_confirmation" name="password_confirmation" class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
        </div>
        <div class="flex justify-end">
            <button type="submit" class="px-6 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700">
                Register
            </button>
        </div>
    </form>
</div>
@endsection
