<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LokasiKantor extends Model
{
    // TAMBAHKAN BARIS INI (agar Laravel mencari tabel 'lokasi_kantor', bukan 'lokasi_kantors')
    protected $table = 'lokasi_kantor';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'nama_gedung',
        'latitude',
        'longitude',
        'radius_meter',
    ];
}