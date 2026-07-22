<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PresensiController;
use App\Http\Controllers\Api\PengajuanController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\UserController;


// ==============================================================================
// 1. PUBLIC ROUTE (Bisa diakses tanpa token/login)
// ==============================================================================
Route::post('/login', [AuthController::class, 'login']);

// --- Route Pegawai (Public / Tanpa Token) ---
Route::get('/pegawai', [UserController::class, 'index']);


// ==============================================================================
// 2. PROTECTED ROUTES (Wajib Menggunakan Bearer Token Sanctum)
// ==============================================================================
Route::middleware('auth:sanctum')->group(function () {

    // --- Dashboard Stats (Web Admin) ---
    Route::get('/dashboard-stats', [DashboardController::class, 'stats']);

    // --- Kelola Pegawai (Web Admin) ---
    Route::post('/pegawai', [UserController::class, 'store']);
    Route::delete('/pegawai/{id}', [UserController::class, 'destroy']);

    // --- Auth & User Profile ---
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // --- Presensi & Lokasi Kantor ---
    Route::get('/office-location', [PresensiController::class, 'getOfficeLocation']);
    Route::post('/presensi', [PresensiController::class, 'store']);

    // --- Pengajuan Izin / Cuti ---
    Route::get('/pengajuan', [PengajuanController::class, 'index']);
    Route::post('/pengajuan', [PengajuanController::class, 'store']);
    
});