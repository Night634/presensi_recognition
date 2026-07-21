<?php

namespace Database\Seeders;

use App\Models\LokasiKantor;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class LokasiKantorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        LokasiKantor::create([
            'nama_gedung'  => 'Gedung Utama Kemensetneg',
            'latitude'     => -6.175392,  // Koordinat sampel/sesuai lokasi asli
            'longitude'    => 106.827153,
            'radius_meter' => 50,         // Radius batas aman (Geofence)
        ]);
    }
}