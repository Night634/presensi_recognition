<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pengajuan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PengajuanController extends Controller
{
    // List Pengajuan untuk Pegawai (Flutter)
    public function index(Request $request)
    {
        $pengajuans = Pengajuan::where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data'   => $pengajuans
        ]);
    }

    // List Semua Pengajuan untuk Admin Portal (Vue JS)
    public function adminIndex()
    {
        try {
            // Mengambil relasi user dengan aman
            $pengajuans = Pengajuan::with(['user' => function ($query) {
                $query->select('id', 'name', 'nip', 'email');
            }])
            ->latest()
            ->get();

            return response()->json([
                'status' => 'success',
                'data'   => $pengajuans
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Gagal mengambil data pengajuan: ' . $e->getMessage()
            ], 500);
        }
    }

    // Pegawai Buat Pengajuan (Flutter)
    public function store(Request $request)
    {
        $request->validate([
            'jenis_pengajuan' => 'required|string',
            'dari_tanggal'    => 'required|date',
            'sampai_tanggal'  => 'required|date',
            'alasan'          => 'required|string',
            'lampiran'        => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $filePath = null;
        if ($request->hasFile('lampiran')) {
            $filePath = $request->file('lampiran')->store('lampiran_pengajuan', 'public');
        }

        $pengajuan = Pengajuan::create([
            'user_id'         => $request->user()->id,
            'jenis_pengajuan' => $request->jenis_pengajuan,
            'dari_tanggal'    => $request->dari_tanggal,
            'sampai_tanggal'  => $request->sampai_tanggal,
            'alasan'          => $request->alasan,
            'lampiran'        => $filePath,
            'status'          => 'PENDING',
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Pengajuan berhasil dikirim.',
            'data'    => $pengajuan
        ], 201);
    }

    // Admin Mengubah Status (Approve / Reject) (Vue JS)
    public function updateStatus(Request $request, $id)
    {
        try {
            // 1. Terima status fleksibel baik DISETUJUHI maupun DISETUJUI
            $rawStatus = strtoupper(trim($request->input('status', '')));

            // 2. Normalisasi status agar konsisten menjadi DISETUJUI
            if ($rawStatus === 'DISETUJUHI' || $rawStatus === 'DISETUJUI') {
                $statusFixed = 'DISETUJUI';
            } elseif ($rawStatus === 'DITOLAK') {
                $statusFixed = 'DITOLAK';
            } else {
                $statusFixed = 'PENDING';
            }

            // 3. Cari data pengajuan
            $pengajuan = Pengajuan::findOrFail($id);

            // 4. Update status & catatan
            $pengajuan->status = $statusFixed;
            if ($request->has('catatan_atasan')) {
                $pengajuan->catatan_atasan = $request->catatan_atasan;
            }
            $pengajuan->save();

            return response()->json([
                'status'  => 'success',
                'message' => 'Status pengajuan berhasil diperbarui.',
                'data'    => $pengajuan
            ], 200);

        } catch (\Exception $e) {
            // Mengembalikan pesan error jelas jika ada kendala di database/model
            return response()->json([
                'status'  => 'error',
                'message' => 'Gagal mengubah status: ' . $e->getMessage()
            ], 500);
        }
    }

    // Pegawai Menghapus Pengajuan (Flutter)
    public function destroy(Request $request, $id)
    {
        $pengajuan = Pengajuan::where('user_id', $request->user()->id)->find($id);

        if (!$pengajuan) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Data pengajuan tidak ditemukan.'
            ], 404);
        }

        if ($pengajuan->lampiran) {
            Storage::disk('public')->delete($pengajuan->lampiran);
        }

        $pengajuan->delete();

        return response()->json([
            'status'  => 'success',
            'message' => 'Pengajuan berhasil dihapus.'
        ]);
    }
}