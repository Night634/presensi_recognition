<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LokasiKantor extends Model
{
    protected $table = 'lokasi_kantor';
    
    protected $fillable = [
        'tipe',
        'nama_gedung',
        'coordinates',
        'latitude',
        'longitude',
        'radius_meter'
    ];

    protected $casts = [
        'coordinates' => 'array',
        'latitude' => 'float',
        'longitude' => 'float',
        'radius_meter' => 'integer',
    ];
}