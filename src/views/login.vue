<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import loginBg from '../assets/image_setneg.png'
import logoSetneg from '../assets/logosetneg.png'
import axios from 'axios';

const router = useRouter()
// State Form
const username = ref('');
const password = ref('');
const rememberMe = ref(false);
const isLoading = ref(false);
const errorMessage = ref('');

const handleSubmit = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    const response = await axios.post('http://127.0.0.1:8000/api/admin/login', {
      nip: username.value,
      password: password.value,
    });

    console.log('Login Success:', response.data);

    const { user, token } = response.data.data;

    // SIMPAN KE sessionStorage (Bukan localStorage)
    sessionStorage.setItem('admin_token', token);
    sessionStorage.setItem('admin_user', JSON.stringify(user));

    // Redirect
    router.push({ name: 'Dashboard' });
    

    // Redirect dengan error catch
    router.push('/dashboard').then(() => {
      console.log('Berhasil navigasi ke /dashboard');
    }).catch(err => {
      console.error('Gagal navigasi router:', err);
    });

  } catch (error) {
    console.error('Login Error:', error);
    if (error.response && error.response.data) {
      errorMessage.value = error.response.data.message || 'Login gagal, periksa NIP dan password.';
    } else {
      errorMessage.value = 'Gagal terhubung ke server.';
    }
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div class="min-h-screen bg-white flex flex-col items-center justify-center p-4 sm:p-6 font-sans">
    
    <!-- Outer Wrapper Canvas -->
    <div class="relative w-full max-w-5xl flex flex-col items-center">
      
      <!-- HERO BANNER BACKGROUND -->
      <div 
        class="relative w-full h-[320px] sm:h-[380px] rounded-[32px] overflow-hidden bg-cover bg-center shadow-sm"
        :style="{ backgroundImage: `url(${loginBg})` }"
      >
        <!-- Soft Overlay -->
        <div class="absolute inset-0 bg-black/20"></div>

        <!-- HEADER LOGO KEMENSETNEG (Pojok Kiri Atas Banner) -->
        <div class="absolute top-6 left-8 z-10 flex items-center space-x-3 text-white">
          <!-- Logo Circle Container -->
          <div class="w-11 h-11 rounded-full bg-white/10 backdrop-blur-xs border border-white/20 flex items-center justify-center overflow-hidden shrink-0">
            <img :src="logoSetneg" alt="Logo Setneg" class="w-8 h-8 object-contain" />
          </div>

          <!-- Vertical Divider -->
          <div class="h-8 w-[1px] bg-white/40"></div>

          <!-- Text -->
          <div class="leading-tight">
            <h2 class="font-extrabold text-[11px] tracking-wider uppercase text-white">
              Kementerian Sekretariat Negara
            </h2>
            <p class="text-[10px] font-semibold text-white/90 tracking-wider uppercase">
              Republik Indonesia
            </p>
          </div>
        </div>
      </div>

      <!-- LOGIN CARD COMPONENT (Floating Overlap Banner) -->
      <div class="relative z-20 -mt-44 sm:-mt-52 w-full max-w-[480px] bg-white rounded-2xl p-8 sm:p-10 shadow-xl border border-gray-200/80">
        
        <!-- Title -->
        <h2 class="text-2xl font-bold text-center text-gray-950 mb-8">Login</h2>
        
        <!-- Error Message -->
        <div v-if="errorMessage" class="p-3.5 mb-4 text-xs font-medium text-red-700 bg-red-100 rounded-lg border border-red-200">
          {{ errorMessage }}
        </div>

        <!-- Form Login (Struktur HTML & Class Tailwind 100% Sama) -->
        <form @submit.prevent="handleSubmit" class="space-y-5">
          <!-- Input Username (diisi NIP) -->
          <div>
            <label class="block text-xs font-bold text-gray-800 mb-1.5">NIP</label>
            <input
              v-model="username"
              type="text"
              placeholder="Input your NIP"
              class="w-full px-3.5 py-2.5 rounded-md border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-600 text-xs text-gray-800 placeholder-gray-400 transition"
            />
          </div>

          <!-- Input Password -->
          <div>
            <label class="block text-xs font-bold text-gray-800 mb-1.5">Password</label>
            <input
              v-model="password"
              type="password"
              placeholder="Input your password"
              class="w-full px-3.5 py-2.5 rounded-md border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-600 text-xs text-gray-800 placeholder-gray-400 transition"
            />
          </div>

          <!-- Checkbox & Forgot Password -->
          <div class="flex items-center justify-between text-xs pt-1">
            <label class="flex items-center space-x-2 cursor-pointer text-gray-700 font-medium">
              <input
                v-model="rememberMe"
                type="checkbox"
                class="w-3.5 h-3.5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-xs">Ingat saya</span>
            </label>

            <a href="#" class="text-blue-600 hover:underline font-medium text-xs">
              Lupa password?
            </a>
          </div>

          <!-- Submit Button -->
          <div class="pt-3">
            <button
              type="submit"
              :disabled="isLoading"
              class="w-full bg-[#0062FF] hover:bg-blue-700 text-white font-semibold text-sm py-3 rounded-xl shadow-xs transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <svg v-if="isLoading" class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ isLoading ? 'Memproses...' : 'Masuk' }}
            </button>
          </div>
        </form>

      </div>
    </div>

  </div>
</template>