<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class UserController extends Controller
{
    private array $faceEmbeddingFailure = [];

    private function faceEmbeddingFailureMessage(): string
    {
        $status = (int) ($this->faceEmbeddingFailure['status'] ?? 0);
        $reason = (string) ($this->faceEmbeddingFailure['reason'] ?? '');
        if ($status === 400 && str_contains($reason, 'face_not_detected')) {
            return 'AI engine terhubung, tetapi wajah tidak terdeteksi. Ambil foto ulang dengan wajah menghadap kamera, cukup terang, dan tidak tertutup.';
        }
        if ($status === 400 && str_contains($reason, 'invalid_image')) {
            return 'File foto tidak terbaca. Ambil ulang foto dengan kamera.';
        }
        if ($status === 503 || $status === 0) {
            return 'Tidak dapat terhubung ke AI engine. Pastikan server AI aktif dan alamat AI_ENGINE_URL benar.';
        }
        return 'AI engine gagal memproses foto (HTTP ' . $status . ($reason ? '; ' . $reason : '') . ').';
    }

    public function register(Request $request)
    {
        $validated = $request->validate([
            'nip' => 'required|string|max:32|unique:users,nip',
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'jabatan' => 'required|string|max:255',
            'password' => 'required|string|min:8|confirmed',
            'foto' => 'required|image|mimes:jpeg,png,jpg|max:5120',
        ]);
        $file = $request->file('foto');
        $bytes = file_get_contents($file->getRealPath());
        $embedding = $this->processFaceEmbedding($bytes, $file->getClientOriginalName());
        if (!$embedding) {
            return response()->json(['message' => $this->faceEmbeddingFailureMessage()], 422);
        }
        $path = $file->store('users', 'public');
        $user = User::create([
            'nip' => $validated['nip'], 'name' => $validated['name'],
            'email' => $validated['email'], 'jabatan' => $validated['jabatan'],
            'password' => Hash::make($validated['password']), 'role' => 'pegawai',
            'status_aktif' => false, 'status_pendaftaran' => 'pending',
            'foto' => asset('storage/' . $path),
            'face_embedding' => is_string($embedding) ? $embedding : json_encode($embedding),
        ]);
        return response()->json([
            'status' => 'success', 'message' => 'Pengajuan registrasi menunggu persetujuan admin.',
            'data' => ['id' => $user->id, 'status_pendaftaran' => $user->status_pendaftaran],
        ], 201);
    }

    public function updateRegistrationStatus(Request $request, $id)
    {
        if ($request->user()?->role !== 'admin') {
            return response()->json(['message' => 'Hanya admin yang dapat menyetujui pendaftaran.'], 403);
        }
        $validated = $request->validate(['status_pendaftaran' => 'required|in:approved,rejected']);
        $user = User::where('role', 'pegawai')->findOrFail($id);
        $approved = $validated['status_pendaftaran'] === 'approved';
        $user->status_pendaftaran = $validated['status_pendaftaran'];
        $user->status_aktif = $approved;
        $user->save();
        $emailSent = false;
        if ($approved) {
            try {
                if (config('mail.default') !== 'smtp'
                    || !config('mail.mailers.smtp.username')
                    || !config('mail.mailers.smtp.password')) {
                    throw new \RuntimeException('SMTP Gmail belum dikonfigurasi.');
                }
                Mail::raw(
                    "Halo {$user->name}, pendaftaran akun Presensi Anda telah disetujui. Silakan masuk menggunakan NIP dan kata sandi yang telah didaftarkan.",
                    fn ($message) => $message->to($user->email)->subject('Akun Presensi telah disetujui'),
                );
                $emailSent = true;
            } catch (\Throwable $exception) {
                Log::error('Registration approval email could not be sent: ' . $exception->getMessage());
            }
        }
        return response()->json([
            'status' => 'success', 'data' => $user->makeHidden(['face_embedding']),
            'email_sent' => $emailSent,
        ]);
    }

    // Menampilkan Form Upload Foto Sederhana
    public function showUploadForm($id)
    {
        $user = User::findOrFail($id);
        return view('admin_upload_face', compact('user'));
    }

    // Private helper: Mengirim gambar ke Colab untuk diekstrak 512 vektor
    private function processFaceEmbedding($imageBytes, $fileName)
    {
        $this->faceEmbeddingFailure = ['status' => 503, 'reason' => 'unreachable'];
        // Gunakan AI_ENGINE_URL (atau kompatibilitas COLAB_URL lama).
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
                $embedding = $result['embedding'] ?? null;
                if (is_array($embedding) && count($embedding) > 0) {
                    return $embedding;
                }
                $this->faceEmbeddingFailure = ['status' => 502, 'reason' => 'embedding_missing'];
                Log::error('AI engine response did not contain an embedding: ' . $response->body());
            } else {
                $body = $response->json();
                $reason = (string) ($body['reason'] ?? $body['detail'] ?? $body['message'] ?? 'unknown_error');
                $this->faceEmbeddingFailure = ['status' => $response->status(), 'reason' => $reason];
                Log::warning('AI engine rejected face embedding: HTTP ' . $response->status() . ' (' . $reason . ')');
            }
        } catch (\Exception $e) {
            $this->faceEmbeddingFailure = ['status' => 503, 'reason' => 'connection_failed'];
            Log::error("Gagal terhubung ke AI engine: " . $e->getMessage());
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
            return back()->with('error', $this->faceEmbeddingFailureMessage());
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

        return response()->json($users->makeHidden(['face_embedding']));
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
        $validated['status_pendaftaran'] = 'approved';
        $validated['password'] = Hash::make($validated['password']);

        // Jika ada foto dikirim dalam format Base64 (baik dari upload berkas maupun kamera)
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
                    'message' => $this->faceEmbeddingFailureMessage()
                ], 422);
            }

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
                    'message' => $this->faceEmbeddingFailureMessage()
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
