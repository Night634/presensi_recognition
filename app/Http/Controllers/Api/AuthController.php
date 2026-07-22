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
        // Validasi: Boleh terima 'nip' (Mobile) ATAU 'email' (Web Admin)
        $request->validate([
            'nip'      => 'nullable|required_without:email',
            'email'    => 'nullable|required_without:nip',
            'password' => 'required',
        ]);

        // Ambil nilai identifier (NIP atau Email)
        $identifier = $request->nip ?? $request->email;

        // Cari user berdasarkan NIP ATAU Email
        $user = User::where('nip', $identifier)
                    ->orWhere('email', $identifier)
                    ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'NIP/Email atau Password salah.',
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