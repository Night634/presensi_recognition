<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center p-4 font-sans">
    
    <!-- Main Outer Container / Image Card -->
    <!-- UKURAN DIKUNCI FIX (h-[560px]) agar tidak berubah/membesar saat berpindah form -->
    <div 
      class="relative w-full max-w-5xl h-[560px] bg-cover bg-center rounded-2xl shadow-lg flex flex-col justify-between p-6 overflow-hidden"
      :style="{ backgroundImage: `url(${loginBg})` }"
    >
      <!-- Dark Overlay Background -->
      <div class="absolute inset-0 bg-black/40 rounded-2xl"></div>

      <!-- Top Header (Logo + Text Setneg) -->
      <div class="relative z-10 flex items-center space-x-3 text-white">
        <img :src="logoSetneg" alt="Logo Setneg" class="h-12 w-auto bg-white/20 p-1.5 rounded-full backdrop-blur-sm" />
        <div>
          <h1 class="text-xs font-bold uppercase tracking-wider leading-tight">Kementerian Sekretariat Negara</h1>
          <p class="text-[10px] font-semibold text-gray-200 uppercase tracking-widest">Republik Indonesia</p>
        </div>
      </div>

      <!-- Floating Form Card Centered -->
      <div class="absolute inset-0 flex items-center justify-center z-20 pointer-events-none p-4">
        <div class="w-full max-w-md bg-white rounded-2xl shadow-2xl p-6 sm:p-8 border border-blue-100 pointer-events-auto transition-all duration-300">
          
          <!-- Mode Login Form -->
          <template v-if="!isForgotPassword">
            <h2 class="text-2xl font-bold text-center text-gray-900 mb-5">Login</h2>

            <!-- Success Alert -->
            <div v-if="successMessage" class="mb-3 bg-green-50 border-l-4 border-green-500 p-2.5 rounded text-xs text-green-700">
              {{ successMessage }}
            </div>

            <!-- Error Alert -->
            <div v-if="errorMessage" class="mb-3 bg-red-50 border-l-4 border-red-500 p-2.5 rounded text-xs text-red-700">
              {{ errorMessage }}
            </div>

            <form class="space-y-3.5" @submit.prevent="handleSubmit">
              <!-- NIP Input -->
              <div>
                <label class="block text-xs font-semibold text-gray-800 mb-1">NIP</label>
                <input 
                  v-model="nip" 
                  type="text" 
                  required 
                  placeholder="Masukkan NIP Anda" 
                  class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm outline-none transition" 
                />
              </div>

              <!-- Password Input -->
              <div>
                <label class="block text-xs font-semibold text-gray-800 mb-1">Password</label>
                <input 
                  v-model="password" 
                  type="password" 
                  required 
                  placeholder="Masukkan password Anda" 
                  class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm outline-none transition" 
                />
              </div>

              <!-- Options -->
              <div class="flex items-center justify-between text-xs pt-1">
                <label class="flex items-center text-gray-700 cursor-pointer">
                  <input v-model="rememberMe" type="checkbox" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" />
                  <span class="ml-2">Ingat saya</span>
                </label>
                <button type="button" @click="toggleForgotPassword(true)" class="text-blue-600 hover:underline">
                  Lupa password?
                </button>
              </div>

              <!-- Submit Button -->
              <div class="pt-1">
                <button 
                  type="submit" 
                  :disabled="isLoading" 
                  class="w-full py-2.5 px-4 rounded-xl text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 active:bg-blue-800 shadow-md transition disabled:opacity-50"
                >
                  <span v-if="isLoading">Memproses...</span>
                  <span v-else>Masuk</span>
                </button>
              </div>
            </form>
          </template>

          <!-- Mode Lupa Password Form -->
          <template v-else>
            <h2 class="text-xl font-bold text-center text-gray-900 mb-1">Reset Password</h2>
            <p class="text-[11px] text-gray-500 text-center mb-4">Masukkan NIP dan password baru Anda.</p>

            <!-- Error Alert Reset -->
            <div v-if="resetErrorMessage" class="mb-3 bg-red-50 border-l-4 border-red-500 p-2.5 rounded text-xs text-red-700">
              {{ resetErrorMessage }}
            </div>

            <!-- Menggunakan spacing ringkas agar muat tanpa meluber -->
            <form class="space-y-2.5" @submit.prevent="handleResetPassword">
              <!-- NIP Input -->
              <div>
                <label class="block text-xs font-semibold text-gray-800 mb-1">NIP</label>
                <input 
                  v-model="resetNip" 
                  type="text" 
                  required 
                  placeholder="Masukkan NIP Anda" 
                  class="w-full px-3 py-1.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs outline-none transition" 
                />
              </div>

              <!-- New Password Input -->
              <div>
                <label class="block text-xs font-semibold text-gray-800 mb-1">Password Baru</label>
                <input 
                  v-model="newPassword" 
                  type="password" 
                  required 
                  placeholder="Masukkan password baru" 
                  class="w-full px-3 py-1.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs outline-none transition" 
                />
              </div>

              <!-- Confirm Password Input -->
              <div>
                <label class="block text-xs font-semibold text-gray-800 mb-1">Konfirmasi Password Baru</label>
                <input 
                  v-model="confirmPassword" 
                  type="password" 
                  required 
                  placeholder="Ulangi password baru" 
                  class="w-full px-3 py-1.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent text-xs outline-none transition" 
                />
              </div>

              <!-- Actions -->
              <div class="pt-2 space-y-1.5">
                <button 
                  type="submit" 
                  :disabled="isLoading" 
                  class="w-full py-2.5 px-4 rounded-xl text-xs font-semibold text-white bg-blue-600 hover:bg-blue-700 active:bg-blue-800 shadow-md transition disabled:opacity-50"
                >
                  <span v-if="isLoading">Memproses...</span>
                  <span v-else>Ubah Password</span>
                </button>

                <button 
                  type="button" 
                  @click="toggleForgotPassword(false)"
                  class="w-full py-1.5 px-4 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-800 transition text-center block"
                >
                  Kembali ke Login
                </button>
              </div>
            </form>
          </template>

        </div>
      </div>

    </div>

  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import loginBg from '../assets/image_setneg.png'
import logoSetneg from '../assets/logosetneg.png'
import { useAdminAuth } from '../composables/useAdminAuth'

const router = useRouter()
const { setAuthData } = useAdminAuth()

// Login State
const nip = ref('')
const password = ref('')
const rememberMe = ref(false)
const isLoading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

// Forgot Password State
const isForgotPassword = ref(false)
const resetNip = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const resetErrorMessage = ref('')

// Toggle View
const toggleForgotPassword = (show) => {
  isForgotPassword.value = show
  errorMessage.value = ''
  resetErrorMessage.value = ''
  if (!show) {
    resetNip.value = ''
    newPassword.value = ''
    confirmPassword.value = ''
  }
}

// Handle Admin Login
const handleSubmit = async () => {
  isLoading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await axios.post('http://127.0.0.1:8000/api/admin/login', {
      nip: nip.value,
      password: password.value,
    })

    const { user, token } = response.data.data
    setAuthData(token, user, rememberMe.value)

    router.push({ name: 'Dashboard' }).catch(() => {
      router.push('/dashboard')
    })
  } catch (error) {
    console.error('Login Error:', error)
    if (error.response && error.response.data) {
      errorMessage.value = error.response.data.message || 'Login gagal, periksa NIP dan password.'
    } else {
      errorMessage.value = 'Gagal terhubung ke server.'
    }
  } finally {
    isLoading.value = false
  }
}

// Handle Reset Password
const handleResetPassword = async () => {
  if (newPassword.value !== confirmPassword.value) {
    resetErrorMessage.value = 'Konfirmasi password baru tidak cocok.'
    return
  }

  isLoading.value = true
  resetErrorMessage.value = ''

  try {
    const response = await axios.post('http://127.0.0.1:8000/api/admin/reset-password', {
      nip: resetNip.value,
      password: newPassword.value,
      password_confirmation: confirmPassword.value
    })

    successMessage.value = response.data.message || 'Password berhasil diperbarui, silakan login.'
    toggleForgotPassword(false)
  } catch (error) {
    console.error('Reset Password Error:', error)
    if (error.response && error.response.data) {
      resetErrorMessage.value = error.response.data.message || 'Gagal mengubah password.'
    } else {
      resetErrorMessage.value = 'Gagal terhubung ke server.'
    }
  } finally {
    isLoading.value = false
  }
}
</script>