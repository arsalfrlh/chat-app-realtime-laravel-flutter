<?php

use App\Http\Controllers\ChatApiController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/chat',[ChatApiController::class,'webIndex']);