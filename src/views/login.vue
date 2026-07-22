<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import loginBg from '../assets/image_setneg.png'
import logoSetneg from '../assets/logosetneg.png'

const router = useRouter()
const username = ref('')
const password = ref('')
const rememberMe = ref(false)
const errorMsg = ref('')
const isLoading = ref(false)

const handleSubmit = () => {
  errorMsg.value = ''
  
  if (!username.value || !password.value) {
    errorMsg.value = 'Username dan password harus diisi!'
    return
  }

  isLoading.value = true

  // Simulasi proses login
  setTimeout(() => {
    // Hardcoded credentials
    if (username.value === 'admin' && password.value === 'admin123') {
      localStorage.setItem('isAuthenticated', 'true')
      localStorage.setItem('username', username.value)
      router.push({ name: 'Dashboard' })
    } else {
      errorMsg.value = 'Username atau password salah!'
      isLoading.value = false
    }
  }, 800)
}
</script>

<template>
  <div class="min-h-screen bg-gray-100 flex items-center justify-center p-4">
    <!-- Main Hero Container -->
    <div 
      class="relative w-full max-w-5xl h-[550px] rounded-3xl overflow-hidden shadow-2xl bg-cover bg-center flex items-center justify-center"
      :style="{ backgroundImage: `url(${loginBg})` }"
    >
      <!-- Dark Overlay -->
      <div class="absolute inset-0 bg-black/40"></div>

      <!-- Header Logo Kemensetneg -->
      <div class="absolute top-6 left-8 z-10 flex items-center space-x-3 text-white">
        <div class="w-12 h-12 bg-amber-500/20 flex items-center justify-center overflow-hidden">
          <img :src="logoSetneg" alt="logo setneg" class="w-full h-full object-cover" />
        </div>
        <div class="leading-tight">
          <h2 class="font-bold text-xs tracking-wider uppercase">Kementerian Sekretariat Negara</h2>
          <p class="text-[10px] text-gray-200 tracking-wider uppercase">Republik Indonesia</p>
        </div>
      </div>

      <!-- Login Card Component -->
      <div class="relative z-20 w-full max-w-md bg-white rounded-2xl p-8 shadow-2xl border border-blue-100 mx-4">
        <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">Login</h2>
        
        <!-- Error Message -->
        <div 
          v-if="errorMsg" 
          class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600 text-center"
        >
          {{ errorMsg }}
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">Username</label>
            <input
              v-model="username"
              type="text"
              placeholder="Input your username"
              class="w-full px-4 py-2.5 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm text-gray-700 placeholder-gray-400 transition"
            />
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">Password</label>
            <input
              v-model="password"
              type="password"
              placeholder="Input your password"
              class="w-full px-4 py-2.5 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm text-gray-700 placeholder-gray-400 transition"
            />
          </div>

          <div class="flex items-center justify-between text-xs pt-1">
            <label class="flex items-center space-x-2 cursor-pointer text-gray-600">
              <input
                v-model="rememberMe"
                type="checkbox"
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span>Ingat saya</span>
            </label>
            <a href="#" class="text-blue-600 hover:underline font-medium">Lupa password?</a>
          </div>

          <button
            type="submit"
            :disabled="isLoading"
            class="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 rounded-lg shadow-md hover:shadow-lg transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            <svg v-if="isLoading" class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {{ isLoading ? 'Memproses...' : 'Masuk' }}
          </button>
        </form>

        <p class="text-xs text-gray-400 text-center mt-6 border-t border-gray-100 pt-4">
          Demo: admin / admin123
        </p>
      </div>
    </div>
  </div>
</template>

