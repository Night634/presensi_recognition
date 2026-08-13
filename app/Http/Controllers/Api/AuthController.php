<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // API LOGIN PEGAWAI / ADMIN
    public function login(Request $request)
    {
        $request->validate([
            'nip' => 'required',
            'password' => 'required',
        ]);

        $user = User::where('nip', $request->nip)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'NIP atau Password salah.',
            ], 401);
        }

        if (! $user->status_aktif) {
            return response()->json([
                'status' => 'error',
                'message' => 'Akun Anda tidak aktif. Silakan hubungi admin.',
            ], 403);
        }

        // Buat Sanctum Token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Login berhasil',
            'data' => [
                'user' => $user,
                'token' => $token,
            ]
        ]);
    }

    // API ME / PROFILE PEGAWAI
    public function profile(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'data' => $request->user(),
        ]);
    }

    // Tambahkan di bawah method login yang sudah ada
public function adminLogin(Request $request)
{
    $request->validate([
        'nip' => 'required',
        'password' => 'required',
    ]);

    // 1. Cek NIP
    $user = User::where('nip', $request->nip)->first();
    if (!$user) {
        return response()->json([
            'status' => 'error',
            'message' => 'NIP ' . $request->nip . ' tidak ditemukan di database.',
        ], 401);
    }

    // 2. Cek Password Hash
    if (!Hash::check($request->password, $user->password)) {
        return response()->json([
            'status' => 'error',
            'message' => 'Password salah/belum di-hash dengan benar.',
        ], 401);
    }

    // 3. Cek Role Admin
    if ($user->role !== 'admin') {
        return response()->json([
            'status' => 'error',
            'message' => 'Akses ditolak! Role user ini adalah: ' . $user->role . ' (harus admin).',
        ], 403);
    }

    // 4. Cek Status Aktif
    if (!$user->status_aktif) {
        return response()->json([
            'status' => 'error',
            'message' => 'Akun status_aktif bernilai false/0.',
        ], 403);
    }

    $token = $user->createToken('admin_token')->plainTextToken;

    return response()->json([
        'status' => 'success',
        'message' => 'Login Admin berhasil',
        'data' => [
            'user' => $user,
            'token' => $token,
        ]
    ]);
}

    // API LOGOUT
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Berhasil log keluar',
        ]);
    }
}