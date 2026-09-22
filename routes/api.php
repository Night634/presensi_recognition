<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\LokasiKantorController;
use App\Http\Controllers\Api\PengajuanController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\KehadiranController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Api\ReminderNotificationController;

Route::middleware('auth:sanctum')->get('/notifications', [NotificationController::class, 'index']);
Route::middleware('auth:sanctum')->get('/kehadiran', [KehadiranController::class, 'index']);

// ==============================================================================
// 1. PUBLIC ROUTE (Bisa diakses tanpa token/login)
// ==============================================================================
Route::post('/login', [AuthController::class, 'login']);
Route::post('/admin/login', [AuthController::class, 'adminLogin']);
Route::post('/admin/reset-password', [AuthController::class, 'resetPassword']);


// ==============================================================================
// 2. PROTECTED ROUTES (Wajib Menggunakan Bearer Token Sanctum dari Flutter)
// ==============================================================================
Route::middleware('auth:sanctum')->group(function () {
    
    // --- Auth & User Profile ---
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/admin/logout', [AuthController::class, 'logout']);

    // --- Presensi & Lokasi Kantor ---
    Route::get('/office-location', [LokasiKantorController::class, 'getOfficeLocation']);
    Route::get('/presensi/hari-ini', [KehadiranController::class, 'checkHariIni']);
    Route::post('/presensi', [KehadiranController::class, 'store']);

    // --- Pengajuan Izin / Cuti ---
    Route::get('/pengajuan', [PengajuanController::class, 'index']);
    Route::post('/pengajuan', [PengajuanController::class, 'store']);
    Route::delete('/pengajuan/{id}', [PengajuanController::class, 'destroy']);

// Route Lokasi yang sudah ada
    Route::get('/lokasi', [LokasiKantorController::class, 'index']);
    Route::post('/lokasi', [LokasiKantorController::class, 'store']);
    Route::put('/lokasi/{id}', [LokasiKantorController::class, 'update']);
    Route::delete('/lokasi/{id}', [LokasiKantorController::class, 'destroy']);

    // ===== ROUTE BARU UNTUK FITUR PENGAJUAN LOKASI =====
    Route::post('/lokasi/pengajuan', [LokasiKantorController::class, 'storePengajuan']); // Dipanggil dari Mobile
    Route::get('/lokasi/pengajuan-list', [LokasiKantorController::class, 'getPengajuanList']); // Dipanggil dari Vue
    Route::post('/lokasi/pengajuan/{id}/approve', [LokasiKantorController::class, 'approvePengajuan']); // Dipanggil dari Vue
    Route::post('/lokasi/pengajuan/{id}/reject', [LokasiKantorController::class, 'rejectPengajuan']); // Dipanggil dari Vue

    Route::apiResource('users', UserController::class);
    
    Route::get('/dashboard/stats', [DashboardController::class, 'index']);

    // Mobile Pegawai (Flutter)
    Route::get('/pengajuan', [PengajuanController::class, 'index']);
    Route::post('/pengajuan', [PengajuanController::class, 'store']);

    // Admin Web Portal (Vue)
    Route::get('/admin/pengajuan', [PengajuanController::class, 'adminIndex']);
    Route::put('/admin/pengajuan/{id}/status', [PengajuanController::class, 'updateStatus']);

    Route::get('/presensi/summary', [KehadiranController::class, 'summary']);
    Route::get('/presensi/history', [KehadiranController::class, 'history']);

    Route::get('/notifications', [ReminderNotificationController::class, 'index']);
    Route::post('/notifications/fcm-token', [ReminderNotificationController::class, 'updateFcmToken']);
    Route::delete('/notifications/{id}', [ReminderNotificationController::class, 'destroy']);
    Route::delete('/notifications-clear-all', [ReminderNotificationController::class, 'clearAll']);

    Route::put('/users/{id}/profile-mobile', [UserController::class, 'updateProfileMobile']);
    Route::put('/users/{id}/password-mobile',[UserController::class, 'updatePasswordMobile']);
});