<?php

use App\Http\Controllers\AuthApiController;
use App\Http\Controllers\ChatApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Broadcast; //tambahkan ini
use Illuminate\Support\Facades\Route;

//buat channels.php di folder "routes/channels.php"
//dan tambahkan konfigurasi dari folder "bootstrap/app.php"

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/login',[AuthApiController::class,'login']);
Route::post('/register',[AuthApiController::class,'register']);

Broadcast::routes(['middleware' => ['auth:sanctum']]); //tambahkan route auth channel private
// dan nama routenya itu jadi http://127.0.0.1:8000/api/broadcasting/auth

Route::middleware('auth:sanctum')->group(function(){
    Route::get('/chat',[ChatApiController::class,'index']);
    Route::get('/chat/room',[ChatApiController::class,'chatRoom']);
    Route::post('/chat/send',[ChatApiController::class,'chatSend']);
    Route::post('/chat/update',[ChatApiController::class,'chatUpdate']);
    Route::delete('/chat/hapus/{id}',[ChatApiController::class,'destroy']);
});