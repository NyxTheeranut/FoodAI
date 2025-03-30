<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Recipe App')</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Playwrite+IN&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
</head>


<body class="bg-gray-50 text-gray-900 font-sans leading-normal tracking-wider">

    <!-- Header Section -->
    <header class="bg-gradient-to-r from-[#aad7d4] to-[#69a6a2] text-white shadow-lg rounded-b-3xl">
        <div class="container mx-auto px-6 py-6 flex justify-between items-center">
            <!-- Logo and Web Name -->
            <div class="flex items-center space-x-4">
                <a href="{{ route('recipes.index') }}" class="flex items-center space-x-2">
                    <img src="https://png.pngtree.com/png-clipart/20230127/original/pngtree-cooking-logo-png-image_8932319.png"
                        alt="Logo" class="h-8 w-auto rounded-full">
                    <span class="text-3xl font-extrabold tracking-wider"
                        style="font-family: 'Playwrite IN', sans-serif;">Recipe Finder</span>
                </a>
            </div>

            <!-- Right Side: Login/Register or Profile Dropdown -->
            <div class="relative">
                @auth
                    <!-- User Profile Dropdown (when logged in) -->
                    <button id="user-dropdown-button"
                        class="flex items-center space-x-2 text-white font-semibold focus:outline-none hover:text-teal-200 transition">
                        <span class="text-lg">{{ Auth::user()->name }}</span>
                        <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                        </svg>
                    </button>
                    <div id="user-dropdown"
                        class="absolute right-0 mt-2 w-48 bg-white text-gray-800 rounded-lg shadow-lg border hidden">
                        <div class="px-4 py-2 font-semibold text-sm text-gray-600">
                            <p>{{ Auth::user()->email }}</p>
                        </div>
                        <a href="{{ route('favorites.index') }}"
                            class="block px-4 py-2 hover:bg-[#8cbd97] cursor-pointer">My Favorites</a>
                        <div class="px-4 py-2 hover:bg-[#8cbd97] cursor-pointer">Settings</div>
                        <div class="px-4 py-2 hover:bg-[#8cbd97] cursor-pointer rounded-b-lg">
                            <form action="{{ route('logout') }}" method="POST">
                                @csrf
                                <button type="submit" class="rounded-b-lg">Logout</button>
                            </form>
                        </div>
                    </div>
                @else
                    <!-- Login/Register (when not logged in) -->
                    <button id="login-register-button"
                        class="text-white font-semibold focus:outline-none hover:text-[#8cbd97] transition">
                        Login / Register
                    </button>
                    <div id="login-register-dropdown"
                        class="absolute right-0 mt-2 w-48 bg-white text-gray-800 rounded-lg shadow-lg border hidden">
                        <a href="{{ route('login') }}"
                            class="block px-4 py-2 hover:bg-[#8cbd97] cursor-pointer rounded-t-lg">Login</a>
                        <a href="{{ route('register') }}"
                            class="block px-4 py-2 hover:bg-[#8cbd97] cursor-pointer rounded-b-lg">Register</a>
                    </div>
                @endauth
            </div>
        </div>
    </header>


    <!-- Main Content Section -->
    <main class="container mx-auto px-6 py-8">
        @yield('content')
    </main>

    <!-- JavaScript for Dropdown -->
    <script>
        // Toggle dropdown visibility when clicking the profile or login/register button
        document.addEventListener('DOMContentLoaded', () => {
            const userDropdownButton = document.getElementById('user-dropdown-button');
            const userDropdown = document.getElementById('user-dropdown');
            const loginRegisterButton = document.getElementById('login-register-button');
            const loginRegisterDropdown = document.getElementById('login-register-dropdown');

            // Show user profile dropdown
            if (userDropdownButton) {
                userDropdownButton.addEventListener('click', () => {
                    userDropdown.classList.toggle('hidden');
                    loginRegisterDropdown.classList.add('hidden'); // Hide login/register dropdown
                });
            }

            // Show login/register dropdown
            if (loginRegisterButton) {
                loginRegisterButton.addEventListener('click', () => {
                    loginRegisterDropdown.classList.toggle('hidden');
                    userDropdown.classList.add('hidden'); // Hide user profile dropdown
                });
            }

            // Close dropdown when clicking outside
            window.addEventListener('click', (e) => {
                if (!e.target.closest('.relative')) {
                    userDropdown.classList.add('hidden');
                    loginRegisterDropdown.classList.add('hidden');
                }
            });
        });
    </script>

</body>

</html>
