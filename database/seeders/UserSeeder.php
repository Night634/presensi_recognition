<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::create([
            'nip' => '199001012023011001',
            'name' => 'Admin Kepegawaian',
            'email' => 'admin@setneg.go.id',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'jabatan' => 'HRD Manager',
            ]);

        User::create([
            'nip' => '199512312023101001',
            'name' => 'Ramzy Atchallah',
            'email' => 'ramzy@setneg.go.id',
            'password' => Hash::make('password123'),
            'role' => 'pegawai',
            'jabatan' => 'Badan Teknologi, Data dan Informasi',

        ]);
    }
}
