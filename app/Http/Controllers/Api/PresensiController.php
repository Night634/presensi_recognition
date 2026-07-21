<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class PresensiController extends Controller
{
    // 1. Mengambil Titik Koordinat Kantor & Radius Aman
    public function getOfficeLocation()
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'name' => 'Kemensetneg Gedung Dua (Jl. Veteran)',
                'latitude' => -6.168305,
                'longitude' => 106.824700,
                'radius_meters' => 150 // Radius aman dalam meter
            ]
        ], 200);
    }

    // 2. Menyimpan Log Presensi (Verifikasi AI Wajah + GPS + Database)
    public function store(Request $request)
    {
        // Validasi input dari Flutter
        $request->validate([
            'latitude'  => 'required',
            'longitude' => 'required',
            'image'     => 'required|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        $user = $request->user();

        // Cek apakah pegawai sudah punya data vektor wajah di DB
        if (!$user->face_embedding) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data wajah Anda belum didaftarkan oleh Admin!'
            ], 400);
        }

        // -------------------------------------------------------------
        // STEP A: VERIFIKASI WAJAH KE SERVER AI COLAB
        // -------------------------------------------------------------
        $verifyUrl = rtrim(env('COLAB_AI_URL'), '/') . '/verify-face';

        try {
            $response = Http::attach(
                'file', 
                file_get_contents($request->file('image')->path()), 
                $request->file('image')->getClientOriginalName()
            )->post($verifyUrl, [
                'db_embedding' => $user->face_embedding
            ]);

            if ($response->failed()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Gagal terhubung ke AI Engine Colab!'
                ], 500);
            }

            $result = $response->json();

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Sistem gagal memproses wajah: ' . $e->getMessage()
            ], 500);
        }

        // -------------------------------------------------------------
        // STEP B: SIMPAN KE DATABASE JIKA WAJAH COCOK (MATCH >= 40%)
        // -------------------------------------------------------------
        if (isset($result['is_match']) && $result['is_match'] === true) {

            // Simpan file foto selfie ke folder storage/app/public/foto_presensi
            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('foto_presensi', 'public');
            }

            // Insert log presensi ke tabel 'kehadirans' (Format & Tipe Data Valid)
            $id = DB::table('kehadirans')->insertGetId([
                'user_id'          => $user->id,
                'tanggal'          => now()->toDateString(),
                'waktu_masuk'      => now(),
                'latitude_masuk'   => $request->latitude,
                'longitude_masuk'  => $request->longitude,
                'foto'             => $imagePath,
                'status_kehadiran' => 'MASUK',
                'created_at'       => now(),
                'updated_at'       => now(),
            ]);

            return response()->json([
                'status'     => 'success',
                'message'    => 'Presensi berhasil terverifikasi & direkam!',
                'similarity' => $result['similarity_score'] . '%',
                'data_id'    => $id
            ], 201);

        } else {
            // Jika wajah tidak cocok, presensi ditolak & TIDAK disimpan ke DB
            return response()->json([
                'status'  => 'error',
                'message' => 'Wajah tidak cocok dengan data pegawai terdaftar!'
            ], 400);
        }
    }
}