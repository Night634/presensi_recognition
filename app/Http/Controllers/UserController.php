<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    // Menampilkan Form Upload Foto Sederhana
    public function showUploadForm($id)
    {
        $user = User::findOrFail($id);
        return view('admin_upload_face', compact('user'));
    }

    // Private helper: Mengirim gambar ke Colab untuk diekstrak 512 vektor
    private function processFaceEmbedding($imageBytes, $fileName)
    {
        // 1. KUNCI DIBETULKAN: Gunakan COLAB_URL (Sesuai .env)
        $colabUrl = config('services.colab.url') ?? env('COLAB_URL');
        if (!$colabUrl) {
            Log::error("COLAB_URL belum di-set di file .env!");
            return null;
        }

        $apiUrl = rtrim($colabUrl, '/') . '/extract-embedding';

        try {
            // 2. HEADER DIBETULKAN: Gunakan header ngrok-skip-browser-warning
            $response = Http::withoutVerifying()
                ->timeout(60)
                ->withHeaders([
                    'ngrok-skip-browser-warning' => 'true',
                    'Accept'                     => 'application/json',
                    'User-Agent'                 => 'Mozilla/5.0'
                ])
                ->attach('file', $imageBytes, $fileName)
                ->post($apiUrl);

            if ($response->successful()) {
                $result = $response->json();
                return $result['embedding'] ?? null;
            } else {
                Log::error("Colab Response Error Code " . $response->status() . ": " . $response->body());
            }
        } catch (\Exception $e) {
            Log::error("Gagal terhubung ke Colab: " . $e->getMessage());
        }

        return null;
    }

    // Memproses Foto -> Kirim ke Colab -> Simpan Vektor 512 ke DB
    public function uploadFace(Request $request, $id)
    {
        $request->validate([
            'foto' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        $user = User::findOrFail($id);
        $file = $request->file('foto');
        
        $embedding = $this->processFaceEmbedding(
            file_get_contents($file->getRealPath()), 
            $file->getClientOriginalName()
        );

        if (!$embedding) {
            return back()->with('error', 'Wajah tidak terdeteksi pada foto atau Colab tidak terhubung! Gunakan foto yang lebih jelas.');
        }

        // 3. FORMAT DIBETULKAN: Pastikan di-encode ke JSON String
        $user->face_embedding = is_string($embedding) ? $embedding : json_encode($embedding);
        $user->save();

        return back()->with('success', 'Berhasil! Vektor 512 data wajah ' . $user->name . ' telah tersimpan di database.');
    }

    // GET: Ambil Semua Pegawai
    public function index()
    {
        $users = User::where('role', 'pegawai')
                    ->orderBy('created_at', 'desc')
                    ->get();

        return response()->json($users);
    }

    // POST: Tambah Pegawai Baru
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nip'          => 'required|string|unique:users,nip',
            'name'         => 'required|string|max:255',
            'email'        => 'required|email|unique:users,email',
            'password'     => 'required|string|min:6',
            'jabatan'      => 'required|string',
            'status_aktif' => 'nullable|boolean',
            'foto'         => 'nullable|string'
        ]);

        $validated['role'] = 'pegawai';
        $validated['status_aktif'] = $request->input('status_aktif', true);
        $validated['password'] = Hash::make($validated['password']);

        // Jika foto dikirim dalam bentuk base64 (Dari kamera WebCam Vue)
        if ($request->filled('foto') && str_contains($request->foto, 'base64')) {
            $imageParts = explode(";base64,", $request->foto);
            $imageType = explode("image/", $imageParts[0])[1] ?? 'png';
            $imageBase64 = base64_decode($imageParts[1]);
            $fileNameOnly = uniqid() . '.' . $imageType;
            $filePath = 'users/' . $fileNameOnly;

            // 1. Simpan foto ke Storage Public
            Storage::disk('public')->put($filePath, $imageBase64);
            $validated['foto'] = asset('storage/' . $filePath);

            // 2. Ekstrak Wajah dari AI Colab
            $embedding = $this->processFaceEmbedding($imageBase64, $fileNameOnly);

            if (!$embedding) {
                return response()->json([
                    'message' => 'Wajah tidak terdeteksi pada foto atau Server AI Colab offline! Harap ambil ulang foto.'
                ], 422);
            }

            // 3. Pastikan di-encode ke JSON String secara pasti
            $validated['face_embedding'] = is_string($embedding) ? $embedding : json_encode($embedding);
        }

        $user = User::create($validated);

        return response()->json($user, 201);
    }

    // PUT: Edit Pegawai
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'nip'          => 'required|string|unique:users,nip,'.$id,
            'name'         => 'required|string|max:255',
            'email'        => 'required|email|unique:users,email,'.$id,
            'jabatan'      => 'required|string',
            'status_aktif' => 'nullable|boolean',
            'foto'         => 'nullable|string'
        ]);

        if ($request->filled('password')) {
            $validated['password'] = Hash::make($request->password);
        } else {
            unset($validated['password']);
        }

        // HANYA OLAH FOTO JIKA USER MEMASUKKAN FOTO BARU (FORMAT BASE64)
        if ($request->filled('foto') && str_contains($request->foto, 'base64')) {
            $imageParts = explode(";base64,", $request->foto);
            $imageType = explode("image/", $imageParts[0])[1] ?? 'png';
            $imageBase64 = base64_decode($imageParts[1]);
            $fileNameOnly = uniqid() . '.' . $imageType;
            $filePath = 'users/' . $fileNameOnly;

            // 1. Simpan foto baru
            Storage::disk('public')->put($filePath, $imageBase64);
            $validated['foto'] = asset('storage/' . $filePath);

            // 2. Update Vector Embedding
            $embedding = $this->processFaceEmbedding($imageBase64, $fileNameOnly);

            if (!$embedding) {
                return response()->json([
                    'message' => 'Wajah baru tidak terdeteksi atau Server AI Colab offline!'
                ], 422);
            }

            $validated['face_embedding'] = is_string($embedding) ? $embedding : json_encode($embedding);
        } else {
            unset($validated['foto']);
        }

        $user->update($validated);

        return response()->json($user);
    }

    // DELETE: Hapus Pegawai
    public function destroy($id)
    {
        $user = User::findOrFail($id);
        $user->delete();

        return response()->json(['message' => 'Pegawai berhasil dihapus']);
    }

    // PUT: Update Data Pribadi dari Mobile
    public function updateProfileMobile(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $id,
            'jabatan' => 'required|string',
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Data pribadi berhasil diperbarui',
            'data' => $user
        ]);
    }


    // PUT: Update Password dari Mobile
    public function updatePasswordMobile(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user->password = Hash::make($validated['password']);
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Password berhasil diperbarui',
        ]);
    }
}