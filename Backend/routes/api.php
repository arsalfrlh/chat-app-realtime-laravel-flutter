<?php

use App\Http\Controllers\ChatApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/chat',[ChatApiController::class,'index']);
Route::post('/chat/tambah',[ChatApiController::class,'create']);
Route::put('/chat/update',[ChatApiController::class,'update']);
Route::delete('/chat/hapus/{id}',[ChatApiController::class,'destroy']);