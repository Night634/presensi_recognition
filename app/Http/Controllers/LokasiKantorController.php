<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\LokasiKantor;
use App\Models\PengajuanLokasi;
use Illuminate\Support\Facades\Log;

class LokasiKantorController extends Controller
{
    public function index()
    {
        return response()->json(LokasiKantor::all());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_gedung' => 'required|string|max:255',
            'coordinates' => 'required|array|min:3',
        ]);

        $validated['tipe'] = 'polygon';
        $lokasi = LokasiKantor::create($validated);
        return response()->json($lokasi, 201);
    }

    public function update(Request $request, $id)
    {
        $lokasi = LokasiKantor::findOrFail($id);

        $validated = $request->validate([
            'nama_gedung' => 'required|string|max:255',
            'coordinates' => 'required|array|min:3',
        ]);

        $lokasi->update($validated);
        return response()->json($lokasi);
    }

    public function destroy($id)
    {
        $lokasi = LokasiKantor::findOrFail($id);
        $lokasi->delete();
        return response()->json(['message' => 'Berhasil dihapus']);
    }

    // --- FITUR BARU: PENGAJUAN LOKASI PEGAWAI (MOBILE) ---

    // POST: Pegawai mengajukan lokasi baru (Radius 30m)
    public function storePengajuan(Request $request)
    {
        $validated = $request->validate([
            'nama_pengaju' => 'required|string',
            'nip_pengaju'  => 'required|string',
            'nama_gedung'  => 'required|string',
            'latitude'     => 'required|numeric',
            'longitude'    => 'required|numeric',
            'radius_meter' => 'nullable|integer',
        ]);

        $pengajuan = PengajuanLokasi::create([
            'nama_pengaju' => $validated['nama_pengaju'],
            'nip_pengaju'  => $validated['nip_pengaju'],
            'nama_gedung'  => $validated['nama_gedung'],
            'latitude'     => $validated['latitude'],
            'longitude'    => $validated['longitude'],
            'radius_meter' => $validated['radius_meter'] ?? 30,
            'status'       => 'pending',
        ]);

        return response()->json([
            'message' => 'Pengajuan lokasi berhasil dikirim',
            'data'    => $pengajuan
        ], 201);
    }

    // 2. Dipanggil Vue Web Admin untuk menampilkan daftar pengajuan
    public function getPengajuanList()
    {
        $list = PengajuanLokasi::orderBy('created_at', 'desc')->get();
        return response()->json($list);
    }

    // 3. Dipanggil Vue Web Admin saat klik tombol Approve
    public function approvePengajuan($id)
    {
        try {
            $pengajuan = PengajuanLokasi::findOrFail($id);
            $pengajuan->update(['status' => 'approved']);

            // Format titik lat, lng menjadi format array polygon/point yang valid
            $lat = (float) $pengajuan->latitude;
            $lng = (float) $pengajuan->longitude;

            // Buat 4 titik kecil melingkari koordinat agar membentuk polygon mini
            $offset = 0.00015; // Sekitar 15-20 meter
            $polyCoords = [
                [$lat + $offset, $lng - $offset],
                [$lat + $offset, $lng + $offset],
                [$lat - $offset, $lng + $offset],
                [$lat - $offset, $lng - $offset],
            ];

            LokasiKantor::create([
                'nama_gedung'  => $pengajuan->nama_gedung,
                'tipe'         => 'radius',
                'radius_meter' => $pengajuan->radius_meter ?? 30,
                'coordinates'  => json_encode($polyCoords), // Encode ke JSON string
            ]);

            return response()->json(['message' => 'Pengajuan disetujui dan lokasi resmi ditambahkan']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal approve: ' . $e->getMessage()], 500);
        }
    }

    public function rejectPengajuan(Request $request, $id)
    {
        try {
            $pengajuan = PengajuanLokasi::findOrFail($id);
            $pengajuan->update([
                'status' => 'rejected',
                'alasan_penolakan' => $request->alasan ?? 'Tidak disetujui admin',
            ]);

            return response()->json(['message' => 'Pengajuan berhasil ditolak']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal menolak: ' . $e->getMessage()], 500);
        }
    }
}