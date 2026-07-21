<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PengajuanController extends Controller
{
    // 1. Mengambil Daftar Riwayat Pengajuan Pegawai Aktif
    public function index(Request $request)
    {
        $user = $request->user();

        $pengajuan = DB::table('pengajuan_izin')
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $pengajuan
        ], 200);
    }

    // 2. Menyimpan Pengajuan Izin/Cuti Baru beserta Lampiran File
    public function store(Request $request)
    {
        $request->validate([
            'jenis_pengajuan' => 'required|string',
            'dari_tanggal'    => 'required|date',
            'sampai_tanggal' => 'required|date',
            'alasan'         => 'required|string',
            'lampiran'       => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:2048',
        ]);

        $user = $request->user();
        $filePath = null;

        // Proses Unggah File Lampiran ke Folder Storage Laravel
        if ($request->hasFile('lampiran')) {
            $file = $request->file('lampiran');
            $filePath = $file->store('lampiran_pengajuan', 'public');
        }

        $id = DB::table('pengajuan_izin')->insertGetId([
            'user_id'         => $user->id,
            'jenis_pengajuan' => $request->jenis_pengajuan,
            'dari_tanggal'    => $request->dari_tanggal,
            'sampai_tanggal' => $request->sampai_tanggal,
            'alasan'         => $request->alasan,
            'lampiran'       => $filePath,
            'status'         => 'PENDING', // Default status awal
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Pengajuan izin berhasil dikirimkan!',
            'data_id' => $id
        ], 201);
    }
}