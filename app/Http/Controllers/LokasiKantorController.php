<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\LokasiKantor;
use Illuminate\Support\Facades\Log;

class LokasiKantorController extends Controller
{
    // GET: List semua lokasi untuk Admin Web / Flutter
    public function index()
    {
        return response()->json(LokasiKantor::all());
    }

    // POST: Tambah lokasi kantor baru oleh Admin
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_gedung' => 'required|string|max:255',
            'coordinates' => 'required|array|min:3',
        ]);

        $lokasi = LokasiKantor::create($validated);
        return response()->json($lokasi, 201);
    }

    // PUT: Update lokasi kantor
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

    // DELETE: Hapus Lokasi
    public function destroy($id)
    {
        $lokasi = LokasiKantor::findOrFail($id);
        $lokasi->delete();
        return response()->json(['message' => 'Berhasil dihapus']);
    }

    // GET: Endpoint khusus Flutter untuk ambil koordinat polygon
    public function getOfficeLocation()
    {
        try {
            $lokasi = LokasiKantor::all();

            return response()->json([
                'status' => 'success',
                'data'   => $lokasi
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error getOfficeLocation: ' . $e->getMessage());

            return response()->json([
                'status'  => 'error',
                'message' => 'Gagal mengambil data lokasi kantor: ' . $e->getMessage()
            ], 500);
        }
    }
}