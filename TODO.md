# TODO - Perbaikan Kamera Tidak Bisa Menyala

## Masalah Teridentifikasi
1. **Android: minSdkVersion tidak diset ke 21** → CameraX plugin butuh minSdk 21
2. **iOS: Info.plist tidak punya NSCameraUsageDescription** → Sistem iOS tolak akses kamera
3. **Inisialisasi kamera tidak pakai global variable** → `presensi_page.dart` panggil `availableCameras()` sendiri
4. **Duplikasi kusus di build.gradle.kts** → Ada `defaultConfig` di luar `android {}` block

## Steps Perbaikan

### Step 1: Fix `android/app/build.gradle.kts` ✅
- [x] Hapus duplikasi `defaultConfig` di luar `android {}` block
- [x] Set `minSdk = 21` di dalam `defaultConfig` block

### Step 2: Fix `ios/Runner/Info.plist` ✅
- [x] Tambahkan key `NSCameraUsageDescription`

### Step 3: Fix `lib/main.dart`
- [ ] Improve error handling untuk inisialisasi kamera (Opsional - sudah cukup baik)

### Step 4: Fix `lib/presensi_page.dart` ✅
- [x] Gunakan variabel global `cameras` dari main.dart
- [x] Hapus pemanggilan `availableCameras()` sendiri
- [x] Tambah error handling & user feedback saat kamera gagal

