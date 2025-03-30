<?php

namespace App\Models;

use App\Http\Controllers\RecipeController;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;


class Favorite extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'recipe_id',
        'recipe_title',
        'recipe_image',
        'view_recipe_url',
    ];

    // Define the relationship to the User model
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Define the relationship to the Recipe model
    public function recipe()
    {
        return $this->belongsTo(RecipeController::class);
    }
}

