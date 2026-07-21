<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class UserController extends Controller
{
    // Menampilkan Form Upload Foto Sederhana
    public function showUploadForm($id)
    {
        $user = User::findOrFail($id);
        return view('admin_upload_face', compact('user'));
    }

    // Memproses Foto -> Kirim ke Colab -> Simpan Vektor 512 ke DB
    public function uploadFace(Request $request, $id)
    {
        $request->validate([
            'foto' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        $user = User::findOrFail($id);
        $colabUrl = env('COLAB_AI_URL');

        if (!$colabUrl) {
            return back()->with('error', 'COLAB_AI_URL belum di-set di file .env!');
        }

        $apiUrl = rtrim($colabUrl, '/') . '/extract-embedding';

        try {
            // Send photo to Colab AI
            $response = Http::attach(
                'file', 
                file_get_contents($request->file('foto')->path()), 
                $request->file('foto')->getClientOriginalName()
            )->post($apiUrl);

            $result = $response->json();

            if ($response->failed() || !isset($result['embedding'])) {
                return back()->with('error', 'Wajah tidak terdeteksi pada foto! Gunakan foto yang lebih jelas.');
            }

            // Simpan Array JSON 512 Vektor langsung ke properti model (bypass $fillable)
            $embeddingData = is_array($result['embedding']) 
                ? json_encode($result['embedding']) 
                : $result['embedding'];

            $user->face_embedding = $embeddingData;
            $user->save(); // <--- Menyimpan secara pasti ke database

            return back()->with('success', 'Berhasil! Vektor 512 data wajah ' . $user->name . ' telah tersimpan di database.');

        } catch (\Exception $e) {
            return back()->with('error', 'Gagal terhubung ke Colab: ' . $e->getMessage());
        }
    }
}