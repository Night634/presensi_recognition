<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/admin/user-face/{id}', [UserController::class, 'showUploadForm']);
Route::post('/admin/user-face/{id}', [UserController::class, 'uploadFace']);
