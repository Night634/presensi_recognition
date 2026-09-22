<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PengajuanLokasi extends Model
{
    use HasFactory;

    protected $table = 'pengajuan_lokasis';

    protected $fillable = [
        'nama_pengaju',
        'nip_pengaju',
        'nama_gedung',
        'latitude',
        'longitude',
        'radius_meter',
        'status',
        'alasan_penolakan',
    ];
}