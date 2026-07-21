<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PresensiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\PengajuanController;

// Public Route (Bisa diakses tanpa login)
Route::post('/login', [AuthController::class, 'login']);

// Protected Routes (Butuh Bearer Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Presensi & Lokasi
    Route::get('/office-location', [PresensiController::class, 'getOfficeLocation']);
    Route::post('/presensi', [PresensiController::class, 'store']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/office-location', [PresensiController::class, 'getOfficeLocation']);
    
    // Tambahkan baris ini untuk menerima request presensi:
    Route::post('/presensi', [PresensiController::class, 'store']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/office-location', [PresensiController::class, 'getOfficeLocation']);
    Route::post('/presensi', [PresensiController::class, 'store']);

    // Route Baru untuk Pengajuan Izin/Cuti
    Route::get('/pengajuan', [PengajuanController::class, 'index']);
    Route::post('/pengajuan', [PengajuanController::class, 'store']);
});
