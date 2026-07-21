<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Upload Foto Pegawai (Temporary Admin)</title>
    <style>
        body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f4f6f9; margin: 0; }
        .card { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); width: 400px; }
        .alert-success { background: #d4edda; color: #155724; padding: 10px; border-radius: 5px; margin-bottom: 15px; }
        .alert-error { background: #f8d7da; color: #721c24; padding: 10px; border-radius: 5px; margin-bottom: 15px; }
        button { background: #007bff; color: white; border: none; padding: 10px 15px; border-radius: 5px; width: 100%; cursor: pointer; font-weight: bold; margin-top: 15px; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>

<div class="card">
    <h3>Registrasi Wajah Pegawai</h3>
    <p>Pegawai: <strong>{{ $user->name }}</strong> ({{ $user->email }})</p>
    <hr>

    @if(session('success'))
        <div class="alert-success">{{ session('success') }}</div>
    @endif

    @if(session('error'))
        <div class="alert-error">{{ session('error') }}</div>
    @endif

    <form action="{{ url('/admin/user-face/' . $user->id) }}" method="POST" enctype="multipart/form-data">
        @csrf
        <label for="foto">Pilih Pasfoto Wajah Ramzy:</label><br><br>
        <input type="file" name="foto" accept="image/*" required>
        
        <button type="submit">Upload & Ekstrak Vektor Wajah</button>
    </form>
</div>

</body>
</html>