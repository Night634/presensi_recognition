<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

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

        if (($user->status_pendaftaran ?? 'approved') === 'pending') {
            return response()->json(['status' => 'error', 'message' => 'Pengajuan akun Anda masih menunggu persetujuan admin.'], 403);
        }
        if (($user->status_pendaftaran ?? 'approved') === 'rejected') {
            return response()->json(['status' => 'error', 'message' => 'Pengajuan akun Anda belum disetujui. Hubungi admin.'], 403);
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
                'message' => ' Username atau password yang anda masukkan salah',
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

    public function resetPassword(Request $request)
    {
        if ($request->user()?->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Hanya admin yang dapat menggunakan endpoint ini.',
            ], 403);
        }

        $request->validate([
            'nip' => 'required',
            'password' => 'required|min:6|confirmed', // 'confirmed' akan memvalidasi field password_confirmation
        ]);

        $user = User::where('nip', $request->nip)->first();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'NIP ' . $request->nip . ' tidak ditemukan.'
            ], 404);
        }

        if (!$user->status_aktif) {
            return response()->json([
                'status' => 'error',
                'message' => 'Akun Anda tidak aktif. Silakan hubungi admin.'
            ], 403);
        }

        // Update password baru
        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Password berhasil diubah. Silakan login dengan password baru.'
        ]);
    }

    // Send a short-lived one-time code to the email registered for this NIP.
    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'nip' => 'required|string|max:32',
        ]);

        $user = User::where('nip', $validated['nip'])->first();
        if ($user && $user->status_aktif && filter_var($user->email, FILTER_VALIDATE_EMAIL)) {
            $code = (string) random_int(100000, 999999);
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $user->email],
                ['token' => Hash::make($code), 'created_at' => now()],
            );

            try {
                Mail::raw(
                    "Kode reset password Presensi Anda: {$code}\n\nKode berlaku selama 10 menit. Jika Anda tidak meminta reset password, abaikan email ini.",
                    function ($message) use ($user): void {
                        $message->to($user->email)->subject('Kode Reset Password Presensi');
                    },
                );
            } catch (\Throwable $exception) {
                Log::error('Password reset email could not be sent: ' . $exception->getMessage());
                DB::table('password_reset_tokens')->where('email', $user->email)->delete();
            }
        }

        // Same response whether or not the NIP exists, to avoid account enumeration.
        $message = 'Jika NIP terdaftar dan aktif, kode reset dikirim ke email akun.';
        if (config('mail.default') === 'log') {
            $message .= ' Mode email lokal aktif; lihat kode di storage/logs/laravel.log.';
        }

        return response()->json([
            'status' => 'success',
            'message' => $message,
        ]);
    }

    public function completePasswordReset(Request $request)
    {
        $validated = $request->validate([
            'nip' => 'required|string|max:32',
            'code' => ['required', 'regex:/^[0-9]{6}$/'],
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::where('nip', $validated['nip'])->where('status_aktif', true)->first();
        if (!$user) {
            return response()->json(['status' => 'error', 'message' => 'Kode reset tidak valid atau sudah kedaluwarsa.'], 422);
        }

        $reset = DB::table('password_reset_tokens')->where('email', $user->email)->first();
        if (!$reset || !$reset->created_at
            || \Illuminate\Support\Carbon::parse($reset->created_at)->lt(now()->subMinutes(10))
            || !Hash::check($validated['code'], $reset->token)) {
            return response()->json(['status' => 'error', 'message' => 'Kode reset tidak valid atau sudah kedaluwarsa.'], 422);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();
        $user->tokens()->delete();
        DB::table('password_reset_tokens')->where('email', $user->email)->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Password berhasil diubah. Silakan login dengan password baru.',
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
