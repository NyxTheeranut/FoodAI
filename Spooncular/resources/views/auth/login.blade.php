<!-- resources/views/auth/login.blade.php -->
@extends('layouts.app')

@section('content')
    <div class="bg-gradient-to-r from-[#aad7d4] to-[#69a6a2] rounded-lg shadow-lg p-8 max-w-4xl mx-auto">
        <form action="{{ route('login') }}" method="POST">
            @csrf
            <div class="mb-4">
                <label for="email" class="block text-gray-700">Email</label>
                <input type="email" id="email" name="email"
                    class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
            </div>
            <div class="mb-4">
                <label for="password" class="block text-gray-700">Password</label>
                <input type="password" id="password" name="password"
                    class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500" required>
            </div>
            <div class="flex justify-end">
                <button type="submit" class="px-6 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700">
                    Login
                </button>
            </div>
        </form>
    </div>
    @if ($errors->any())
        <div class="bg-red-500 text-white p-4 rounded-lg mb-4 mt-5">
            <ul>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

@endsection
