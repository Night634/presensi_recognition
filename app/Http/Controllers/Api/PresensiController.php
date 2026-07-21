<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PresensiController extends Controller
{
    // 1. Mengambil Titik Koordinat Kantor & Radius Aman
    public function getOfficeLocation()
    {
        // Contoh koordinat Kemensetneg Gedung Utama (atau koordinat tes)
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

    // 2. Menyimpan Log Presensi (GPS & Foto Selfie)
    public function store(Request $request)
    {
        $request->validate([
            'latitude'  => 'required',
            'longitude' => 'required',
            'image'     => 'required|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        $user = $request->user();
        $imagePath = null;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('foto_presensi', 'public');
        }

        $id = DB::table('kehadiran')->insertGetId([
            'user_id'    => $user->id,
            'tanggal'    => now()->toDateString(),
            'jam_masuk'  => now()->toTimeString(),
            'latitude'   => $request->latitude,
            'longitude'  => $request->longitude,
            'foto'       => $imagePath,
            'status'     => 'MASUK',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Presensi berhasil direkam!',
            'data_id' => $id
        ], 201);
    }
}