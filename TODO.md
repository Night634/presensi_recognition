# TODO - Halaman Lokasi Absensi

## ✅ Completed Steps:

1. ✅ **Install Leaflet** — `leaflet` package sudah terinstall
2. ✅ **Tambah Route `/lokasi`** — di `src/router/index.js`
3. ✅ **Update Navigasi di Semua Halaman** — Menambahkan item "Lokasi" dengan icon `MapPin` ke:
   - `dashboard.vue`
   - `pegawai.vue`
   - `presensi.vue`
   - `cuti.vue`
4. ✅ **Buat Halaman `lokasi.vue`** dengan Leaflet + OpenStreetMap (GRATIS):
   - Layout konsisten (Sidebar + Header Navbar + Notifikasi drawer)
   - **Peta Leaflet interaktif** dengan OpenStreetMap tiles (gratis, tanpa token)
   - **Marker & Circle area** untuk setiap lokasi absensi di peta utama
   - **Tabel daftar wilayah** (Nama, Latitude, Longitude, Radius, Aksi)
   - **Modal Tambah Wilayah** dengan:
     - Input nama lokasi
     - Peta mini Leaflet — klik untuk menentukan titik koordinat
     - Circle preview otomatis saat radius diubah
     - Input Latitude, Longitude (readonly otomatis), Radius
   - **Tombol Lihat** — fly-to peta ke lokasi tertentu
   - **Tombol Hapus** — menghapus wilayah & update peta
   - **Search & Pagination** (sama seperti halaman lain)
   - **Data dummy** 5 lokasi contoh di area Jakarta

