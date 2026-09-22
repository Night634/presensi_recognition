<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import logoSetneg from '../assets/logosetneg.png'
import { useNotifications } from '../composables/useNotifications'
import { useAdminAuth } from '../composables/useAdminAuth'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin,
  LogOut, Bell, Search, Camera, Upload, ArrowLeft,
  ChevronLeft, ChevronRight, User as UserIcon, Menu, X, RefreshCw
} from 'lucide-vue-next'

const router = useRouter()
const API_URL = 'http://127.0.0.1:8000/api/users'

const { getAuthHeader, handleLogout } = useAdminAuth()

// State Interface/UI
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const isLoading = ref(false)
const isSubmitting = ref(false)

// State Navigasi Tampilan ( 'list' | 'form' )
const currentView = ref('list') 
const isEditMode = ref(false)
const editingId = ref(null)

const formPegawai = ref({
  nip: '',
  name: '',
  email: '',
  password: '',
  jabatan: '',
  status_aktif: true,
  foto: null
})

// State Kamera WebCam & Upload
const photoMode = ref('upload') // 'upload' | 'camera'
const kameraAktif = ref(false)
const videoStream = ref(null)
const videoRef = ref(null)
const canvasRef = ref(null)
const cameraFrame = ref(null)
const fotoPreview = ref(null)
const fileInputRef = ref(null)

// State Search, Data, & Pagination
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(10)
const activeMenu = ref('Pegawai')

// Master Data Pegawai (From API)
const pegawaiList = ref([])
const { notifications, fetchNotifications, removeNotification, clearAllNotif } = useNotifications()

const toggleNotifications = async () => {
  isNotifOpen.value = !isNotifOpen.value
  if (isNotifOpen.value) {
    await fetchNotifications()
  }
}

// ===== API CRUD OPERATIONS =====

const fetchPegawai = async () => {
  isLoading.value = true

  try {
    const res = await axios.get(API_URL, getAuthHeader())

    if (Array.isArray(res.data)) {
      pegawaiList.value = res.data
    } else if (res.data && Array.isArray(res.data.data)) {
      pegawaiList.value = res.data.data
    } else {
      pegawaiList.value = []
    }
  } catch (error) {
    console.error('Gagal mengambil data pegawai:', error)
    pegawaiList.value = []
  } finally {
    isLoading.value = false
  }
}

const handleSubmit = async () => {
  isSubmitting.value = true
  try {
    const payload = {
      nip: formPegawai.value.nip,
      name: formPegawai.value.name,
      email: formPegawai.value.email,
      jabatan: formPegawai.value.jabatan,
      role: 'pegawai',
      status_aktif: formPegawai.value.status_aktif ? 1 : 0,
      foto: fotoPreview.value || formPegawai.value.foto || ''
    }

    if (!isEditMode.value) {
      payload.password = formPegawai.value.password || '12345678'
    } else if (formPegawai.value.password) {
      payload.password = formPegawai.value.password
    }

    if (isEditMode.value) {
      await axios.put(`${API_URL}/${editingId.value}`, payload, getAuthHeader())
    } else {
      await axios.post(API_URL, payload, getAuthHeader())
    }

    await fetchPegawai()
    handleBackToList()
    alert(isEditMode.value ? 'Berhasil mengupdate pegawai!' : 'Berhasil menambah pegawai!')
  } catch (error) {
    console.error('Gagal menyimpan data pegawai:', error)
    const serverMessage = error.response?.data?.message
    const validationErrors = error.response?.data?.errors

    if (validationErrors) {
      const firstKey = Object.keys(validationErrors)[0]
      alert(`Validasi Gagal (${firstKey}): ${validationErrors[firstKey][0]}`)
    } else if (serverMessage) {
      alert(`Error: ${serverMessage}`)
    } else {
      alert('Gagal menyimpan data pegawai!')
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = async (id) => {
  if (!confirm('Apakah Anda yakin ingin menghapus pegawai ini?')) return
  try {
    await axios.delete(`${API_URL}/${id}`, getAuthHeader())
    await fetchPegawai()
  } catch (error) {
    console.error('Gagal menghapus pegawai:', error)
    alert('Gagal menghapus pegawai!')
  }
}

// ===== NAVIGASI PAGE & FORM HANDLER =====

const openFormPage = (item = null) => {
  resetForm()
  if (item) {
    isEditMode.value = true
    editingId.value = item.id
    formPegawai.value = {
      nip: item.nip || '',
      name: item.name || '',
      email: item.email || '',
      password: '',
      jabatan: item.jabatan || '',
      status_aktif: item.status_aktif !== undefined ? Boolean(item.status_aktif) : true,
      foto: item.foto || null
    }
    fotoPreview.value = item.foto || null
  } else {
    isEditMode.value = false
    editingId.value = null
  }
  currentView.value = 'form'
}

const handleBackToList = () => {
  currentView.value = 'list'
  stopCamera()
  resetForm()
}

const resetForm = () => {
  formPegawai.value = {
    nip: '',
    name: '',
    email: '',
    password: '',
    jabatan: '',
    status_aktif: true,
    foto: null
  }
  fotoPreview.value = null
  photoMode.value = 'upload'
  stopCamera()
}

// ===== UPLOAD FOTO & KAMERA =====

const handleFileUpload = (event) => {
  const file = event.target.files[0]
  if (!file) return

  if (!file.type.startsWith('image/')) {
    alert('Harap pilih file gambar (JPG/PNG).')
    return
  }

  const reader = new FileReader()
  reader.onload = (e) => {
    fotoPreview.value = e.target.result
    formPegawai.value.foto = e.target.result
  }
  reader.readAsDataURL(file)
}

const drawToCanvas = () => {
  if (!kameraAktif.value || !videoRef.value || !canvasRef.value) return
  const video = videoRef.value
  const canvas = canvasRef.value
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  if (video.videoWidth && video.videoHeight) {
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
  }
  ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
  cameraFrame.value = requestAnimationFrame(drawToCanvas)
}

const startCamera = async () => {
  if (!navigator.mediaDevices?.getUserMedia) {
    alert('Kamera tidak tersedia pada perangkat/browser ini.')
    return
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false })
    videoStream.value = stream
    kameraAktif.value = true
    if (videoRef.value) {
      videoRef.value.srcObject = stream
      await videoRef.value.play()
    }
    cameraFrame.value = requestAnimationFrame(drawToCanvas)
  } catch (error) {
    console.error(error)
    alert('Tidak dapat mengakses kamera. Pastikan izin kamera telah diaktifkan.')
  }
}

const stopCamera = () => {
  if (videoStream.value) {
    videoStream.value.getTracks().forEach(track => track.stop())
    videoStream.value = null
  }
  if (cameraFrame.value) {
    cancelAnimationFrame(cameraFrame.value)
    cameraFrame.value = null
  }
  kameraAktif.value = false
}

const capturePhoto = () => {
  if (!videoRef.value) return

  const video = videoRef.value
  const canvas = document.createElement('canvas')
  canvas.width = video.videoWidth || 640
  canvas.height = video.videoHeight || 480
  const ctx = canvas.getContext('2d')

  if (ctx) {
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    fotoPreview.value = canvas.toDataURL('image/png')
    formPegawai.value.foto = fotoPreview.value
  }

  stopCamera()
}

// ===== COMPUTED & PAGINATION =====

const filteredPegawai = computed(() => {
  if (!Array.isArray(pegawaiList.value)) return []
  return pegawaiList.value.filter(p => {
    const isPegawai = p.role === 'pegawai' || p.role !== 'admin'
    const matchSearch = 
      (p.name && p.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
      (p.nip && String(p.nip).includes(searchQuery.value)) ||
      (p.jabatan && p.jabatan.toLowerCase().includes(searchQuery.value.toLowerCase()))

    return isPegawai && matchSearch
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredPegawai.value.length / pageSize.value)))
const paginatedPegawai = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredPegawai.value.slice(start, start + pageSize.value)
})

const displayFrom = computed(() => filteredPegawai.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredPegawai.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => { currentPage.value = 1 })
const goToPrevPegawai = () => { if (currentPage.value > 1) currentPage.value -= 1 }
const goToNextPegawai = () => { if (currentPage.value < totalPages.value) currentPage.value += 1 }

const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, route: 'Dashboard' },
  { name: 'Pegawai', icon: Users, route: 'Pegawai' },
  { name: 'Presensi', icon: Scan, route: 'Presensi' },
  { name: 'Cuti', icon: CalendarCheck, route: 'Cuti' },
  { name: 'Lokasi', icon: MapPin, route: 'Lokasi' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push({ name: item.route })
}

onMounted(() => {
  fetchPegawai()
  fetchNotifications()
})

onUnmounted(() => {
  stopCamera()
})
</script>

<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden">
    
    <!-- OVERLAY MOBILE -->
    <div 
      v-if="isSidebarOpen" 
      @click="toggleSidebar"
      class="fixed inset-0 bg-black/60 backdrop-blur-xs z-40 lg:hidden transition-opacity"
    ></div>

    <!-- SIDEBAR -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 w-64 bg-[#0A1128] border-r border-[#131C38] flex flex-col justify-between z-50 transition-transform duration-300 ease-in-out shrink-0',
        isSidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0 shadow-none'
      ]"
    >
      <div>
        <!-- HEADER LOGO SETNEG DIGITAL -->
        <div class="pt-8 pb-6 px-6 flex flex-col items-center justify-center text-center relative border-b border-[#131C38]/50">
          <!-- Tombol Close Mobile -->
          <button @click="toggleSidebar" class="lg:hidden absolute top-4 right-4 text-white/70 hover:text-white transition">
            <X class="w-5 h-5" />
          </button>

          <h1 class="font-bold text-base text-white tracking-wide">Setneg Digital</h1>
          <p class="text-[11px] text-slate-400 font-medium tracking-wider mt-0.5">Guest Access Control</p>
        </div>

        <!-- NAVIGATION MENU -->
        <nav class="mt-6 px-4 space-y-2.5">
          <button
            v-for="item in navItems"
            :key="item.name"
            @click="navigateTo(item)"
            :class="[
              'w-full flex items-center px-5 py-3.5 rounded-2xl transition-all duration-200 text-sm font-semibold tracking-wide',
              
              // Style Khusus jika Menu adalah 'Scan Wajah' (Tombol Utama Biru Terang)
              item.isSpecial 
                ? 'bg-[#0066FF] hover:bg-[#0052CC] text-white shadow-lg shadow-blue-600/30' 
                
              // Style untuk Menu Aktif Biasa (Biru Gelap Solid seperti di gambar)
                : activeMenu === item.name 
                  ? 'bg-[#003B95] text-white shadow-md' 
                  
              // Style Default / Normal
                  : 'text-slate-300 hover:text-white hover:bg-[#162248]/60'
            ]"
          >
            <div class="flex items-center space-x-3.5">
              <component 
                :is="item.icon" 
                class="w-5 h-5 shrink-0" 
                stroke-width="2.2"
              />
              <span>{{ item.name }}</span>
            </div>
          </button>
        </nav>
      </div>

      <!-- FOOTER / LOGOUT -->
      <div class="p-4 border-t border-[#131C38]/50">
        <button 
          @click="handleLogout" 
          class="flex items-center space-x-3.5 px-5 py-3.5 text-sm font-semibold text-slate-300 hover:text-white hover:bg-red-500/10 hover:text-red-400 rounded-2xl w-full transition duration-150"
        >
          <LogOut class="w-5 h-5 shrink-0" stroke-width="2" />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>

    <!-- MAIN WRAPPER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      
      <!-- HEADER NAVBAR -->
      <header class="h-16 flex items-center justify-between px-4 sm:px-8 z-30 shrink-0 bg-white border-b border-gray-100">
        <div class="flex items-center space-x-3 min-w-0">
          <!-- Button Mobile Menu -->
          <button @click="isSidebarOpen = true" class="p-2 -ml-2 text-gray-600 lg:hidden hover:text-[#38BDF8] transition shrink-0">
            <Menu class="w-6 h-6" />
          </button>
          
          <div class="flex items-center space-x-3 min-w-0">
            <!-- Container Logo (Tambahkan shrink-0) -->
            <div class="w-8 h-8 rounded flex items-center justify-center shrink-0">
              <img :src="logoSetneg" alt="Logo Setneg" class="w-full h-full object-contain" />
            </div>

            <!-- Teks Kementerian (Bisa memendek rapi dengan truncate) -->
            <span class="font-bold text-xs uppercase tracking-wide text-gray-700 truncate">
              Kementerian Sekretariat Negara Republik Indonesia
            </span>
          </div>
        </div>

        <!-- Button Notifikasi -->
        <button @click="toggleNotifications" class="p-2 text-gray-600 hover:text-[#38BDF8] hover:bg-gray-100 rounded-full transition relative shrink-0 ml-2">
          <Bell class="w-6 h-6" />
        </button>
      </header>

      <!-- MAIN PAGE CONTENT -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        
        <!-- TAMPILAN 1: LIST PEGAWAI -->
        <template v-if="currentView === 'list'">
          <div>
            <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
            <h1 class="text-2xl font-bold text-gray-950">Kelola Data Pegawai</h1>
          </div>

          <!-- Search Bar & Add Button -->
          <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
            <div class="relative w-full sm:w-80">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Cari NIP, nama, jabatan..."
                class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition shadow-xs"
              />
              <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
            </div>
            <button
              @click="openFormPage()"
              class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl shadow-md shadow-blue-500/20 transition duration-150 text-center"
            >
              + Tambah Pegawai
            </button>
          </div>

          <!-- TABLE DATA PEGAWAI -->
          <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse min-w-[650px]">
                <thead>
                  <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-gray-50/50">
                    <th class="py-4 px-6 text-center w-16">No</th>
                    <th class="py-4 px-6 text-center w-20">Foto</th>
                    <th class="py-4 px-6">Nama</th>
                    <th class="py-4 px-6">NIP</th>
                    <th class="py-4 px-6">Jabatan / Status</th>
                    <th class="py-4 px-6 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm font-medium text-gray-800">
                  <tr 
                    v-for="(pegawai, index) in paginatedPegawai" 
                    :key="pegawai.id"
                    class="hover:bg-gray-50/80 transition"
                  >
                    <td class="py-4 px-6 text-center text-gray-900 font-semibold">{{ displayFrom + index }}</td>
                    
                    <td class="py-4 px-6 text-center">
                      <div class="w-10 h-10 rounded-full bg-gray-200 mx-auto overflow-hidden border border-gray-200 flex items-center justify-center">
                        <img v-if="pegawai.foto" :src="pegawai.foto" alt="Foto" class="w-full h-full object-cover" />
                        <UserIcon v-else class="w-5 h-5 text-gray-400" />
                      </div>
                    </td>

                    <td class="py-4 px-6 text-gray-900 font-semibold">
                      <div>{{ pegawai.name }}</div>
                      <div class="text-[11px] text-gray-400 font-normal">{{ pegawai.email }}</div>
                    </td>
                    <td class="py-4 px-6 text-gray-900 font-semibold">{{ pegawai.nip }}</td>
                    <td class="py-4 px-6 text-gray-900 font-semibold">
                      <div class="flex items-center space-x-2">
                        <span>{{ pegawai.jabatan || '-' }}</span>
                        <span 
                          :class="[
                            'px-2 py-0.5 rounded-md text-[10px] font-bold',
                            pegawai.status_aktif ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                          ]"
                        >
                          {{ pegawai.status_aktif ? 'Aktif' : 'Nonaktif' }}
                        </span>
                      </div>
                    </td>
                    <td class="py-4 px-6">
                      <div class="flex items-center justify-center space-x-2">
                        <button 
                          @click="openFormPage(pegawai)"
                          class="bg-blue-500 hover:bg-blue-600 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
                        >
                          Edit
                        </button>
                        <button 
                          @click="handleDelete(pegawai.id)"
                          class="bg-red-600 hover:bg-red-700 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>

                  <tr v-if="paginatedPegawai.length === 0">
                    <td colspan="6" class="py-8 text-center text-gray-400 text-sm">
                      {{ isLoading ? 'Memuat data pegawai...' : 'Tidak ada data pegawai yang ditemukan.' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- PAGINATION BAR -->
          <div class="flex flex-col sm:flex-row items-center justify-end gap-4 text-xs font-medium text-gray-600 pt-2">
            <div class="flex items-center space-x-2">
              <span>Halaman:</span>
              <select v-model="currentPage" class="border border-gray-300 rounded-md px-2 py-1 bg-white focus:outline-none text-xs">
                <option v-for="page in totalPages" :key="page" :value="page">{{ page }}</option>
              </select>
            </div>

            <span>{{ displayFrom }} - {{ displayTo }} dari {{ filteredPegawai.length }}</span>

            <div class="flex items-center space-x-1">
              <button @click="goToPrevPegawai" :disabled="currentPage === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
                <ChevronLeft class="w-4 h-4" />
              </button>
              <button @click="goToNextPegawai" :disabled="currentPage === totalPages" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30">
                <ChevronRight class="w-4 h-4" />
              </button>
            </div>
          </div>
        </template>

        <!-- TAMPILAN 2: HALAMAN FORM TAMBAH / EDIT PEGAWAI -->
        <template v-else-if="currentView === 'form'">
          <div class="space-y-6 max-w-4xl mx-auto">
            
            <!-- Header Halaman & Tombol Back -->
            <div class="flex items-center justify-between pb-4 border-b border-gray-200">
              <div class="flex items-center space-x-4">
                <button 
                  @click="handleBackToList" 
                  class="p-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-700 transition flex items-center justify-center shadow-xs"
                >
                  <ArrowLeft class="w-5 h-5" />
                </button>
                <div>
                  <h1 class="text-2xl font-bold text-gray-900">
                    {{ isEditMode ? 'Edit Data Pegawai' : 'Tambah Pegawai Baru' }}
                  </h1>
                  <p class="text-xs text-gray-500">Isi kelengkapan data dan foto wajah pegawai di bawah ini.</p>
                </div>
              </div>
            </div>

            <!-- Card Form Layout -->
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 sm:p-8">
              <form @submit.prevent="handleSubmit" class="space-y-6">
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  
                  <!-- Kolom Kiri: Input Field -->
                  <div class="space-y-4">
                    <h3 class="text-sm font-bold text-gray-800 border-b pb-2">Informasi Akun & Data Diri</h3>

                    <!-- NIP -->
                    <div>
                      <label class="block text-xs font-semibold text-gray-700 mb-1">NIP</label>
                      <input
                        v-model="formPegawai.nip"
                        type="text"
                        placeholder="Masukkan NIP pegawai"
                        class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                        required
                      />
                    </div>

                    <!-- Nama -->
                    <div>
                      <label class="block text-xs font-semibold text-gray-700 mb-1">Nama Lengkap</label>
                      <input
                        v-model="formPegawai.name"
                        type="text"
                        placeholder="Masukkan nama lengkap"
                        class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                        required
                      />
                    </div>

                    <!-- Email -->
                    <div>
                      <label class="block text-xs font-semibold text-gray-700 mb-1">Email</label>
                      <input
                        v-model="formPegawai.email"
                        type="email"
                        placeholder="contoh@setneg.go.id"
                        class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                        required
                      />
                    </div>

                    <!-- Password -->
                    <div>
                      <label class="block text-xs font-semibold text-gray-700 mb-1">
                        Password {{ isEditMode ? '(Isi jika ingin diubah)' : '' }}
                      </label>
                      <input
                        v-model="formPegawai.password"
                        type="password"
                        placeholder="******"
                        :required="!isEditMode"
                        class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                      />
                    </div>

                    <!-- Jabatan & Status -->
                    <div class="grid grid-cols-2 gap-3">
                      <div>
                        <label class="block text-xs font-semibold text-gray-700 mb-1">Jabatan / Posisi</label>
                        <input
                          v-model="formPegawai.jabatan"
                          type="text"
                          placeholder="Contoh: Staff IT"
                          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                          required
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold text-gray-700 mb-1">Status Aktif</label>
                        <select
                          v-model="formPegawai.status_aktif"
                          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                        >
                          <option :value="true">Aktif</option>
                          <option :value="false">Nonaktif</option>
                        </select>
                      </div>
                    </div>
                  </div>

                  <!-- Kolom Kanan: Foto Wajah (Upload / Kamera) -->
                  <div class="space-y-4">
                    <h3 class="text-sm font-bold text-gray-800 border-b pb-2">Foto Wajah (Presensi AI)</h3>

                    <!-- Selector Tab Mode Foto -->
                    <div class="flex bg-gray-100 p-1 rounded-xl">
                      <button 
                        type="button" 
                        @click="photoMode = 'upload'; stopCamera()"
                        :class="['flex-1 py-1.5 text-xs font-semibold rounded-lg transition flex items-center justify-center space-x-2', photoMode === 'upload' ? 'bg-white shadow-xs text-blue-600' : 'text-gray-500']"
                      >
                        <Upload class="w-3.5 h-3.5" />
                        <span>Upload Berkas</span>
                      </button>
                      <button 
                        type="button" 
                        @click="photoMode = 'camera'"
                        :class="['flex-1 py-1.5 text-xs font-semibold rounded-lg transition flex items-center justify-center space-x-2', photoMode === 'camera' ? 'bg-white shadow-xs text-blue-600' : 'text-gray-500']"
                      >
                        <Camera class="w-3.5 h-3.5" />
                        <span>Ambil Kamera</span>
                      </button>
                    </div>

                    <!-- MODE 1: UPLOAD FILE -->
                    <div v-if="photoMode === 'upload'" class="space-y-3">
                      <input 
                        type="file" 
                        ref="fileInputRef" 
                        @change="handleFileUpload" 
                        accept="image/*" 
                        class="hidden" 
                      />
                      
                      <div 
                        @click="$refs.fileInputRef.click()"
                        class="border-2 border-dashed border-gray-300 hover:border-blue-500 bg-gray-50/50 hover:bg-blue-50/20 rounded-2xl h-64 flex flex-col items-center justify-center p-4 cursor-pointer transition relative overflow-hidden"
                      >
                        <template v-if="fotoPreview">
                          <img :src="fotoPreview" alt="Preview Foto" class="w-full h-full object-cover rounded-xl" />
                          <div class="absolute inset-0 bg-black/30 flex items-center justify-center opacity-0 hover:opacity-100 transition rounded-xl">
                            <span class="text-white text-xs font-semibold bg-black/60 px-3 py-1.5 rounded-lg">Ganti Foto</span>
                          </div>
                        </template>
                        <template v-else>
                          <div class="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-2">
                            <Upload class="w-6 h-6" />
                          </div>
                          <p class="text-xs font-semibold text-gray-700">Klik untuk upload foto pegawai</p>
                          <p class="text-[10px] text-gray-400 mt-1">Format JPG atau PNG (Maks 5MB)</p>
                        </template>
                      </div>
                    </div>

                    <!-- MODE 2: AMBIL FOTO KAMERA -->
                    <div v-else-if="photoMode === 'camera'" class="space-y-3">
                      <div class="bg-gray-900 rounded-2xl h-64 flex items-center justify-center relative overflow-hidden shadow-inner">
                        <canvas ref="canvasRef" class="w-full h-full object-cover"></canvas>
                        <video ref="videoRef" class="hidden" autoplay muted playsinline></video>

                        <div v-if="!kameraAktif && !fotoPreview" class="absolute inset-0 flex flex-col items-center justify-center text-gray-400">
                          <Camera class="w-10 h-10 mb-2" />
                          <span class="text-xs">Kamera Belum Aktif</span>
                        </div>

                        <div v-if="!kameraAktif && fotoPreview" class="absolute inset-0">
                          <img :src="fotoPreview" alt="Preview Foto" class="w-full h-full object-cover" />
                        </div>

                        <div class="absolute bottom-3 inset-x-0 flex justify-center space-x-2 px-4">
                          <button
                            type="button"
                            @click="kameraAktif ? capturePhoto() : startCamera()"
                            class="bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold px-4 py-2 rounded-xl shadow-md transition"
                          >
                            {{ kameraAktif ? 'Ambil Jepretan' : (fotoPreview ? 'Foto Ulang Kamera' : 'Aktifkan Kamera') }}
                          </button>
                        </div>
                      </div>
                    </div>

                  </div>

                </div>

                <!-- Action Buttons Submit / Cancel -->
                <div class="flex items-center justify-end space-x-3 pt-6 border-t border-gray-100">
                  <button
                    type="button"
                    @click="handleBackToList"
                    class="px-6 py-2.5 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 text-xs font-semibold rounded-xl transition"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    :disabled="isSubmitting"
                    class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-xl shadow-md transition disabled:opacity-50"
                  >
                    {{ isSubmitting ? 'Menyimpan...' : (isEditMode ? 'Update Data Pegawai' : 'Simpan Pegawai Baru') }}
                  </button>
                </div>

              </form>
            </div>

          </div>
        </template>

      </main>
    </div>

    <!-- DRAWER NOTIFIKASI -->
    <div v-if="isNotifOpen" class="absolute top-16 right-0 w-80 bg-white border-l border-b border-gray-200 shadow-xl z-50 p-4 transition-all">
      <div class="flex items-center justify-between pb-3 border-b border-gray-100">
        <h3 class="font-bold text-sm text-gray-800">Notifications</h3>
        <div class="flex items-center space-x-3">
          <button @click="clearAllNotif" class="text-xs text-gray-500 hover:text-gray-800 font-medium">Clear All</button>
          <button @click="isNotifOpen = false" class="text-gray-400 hover:text-gray-600"><X class="w-4 h-4" /></button>
        </div>
      </div>
      <div class="divide-y divide-gray-50 max-h-96 overflow-y-auto">
        <div v-for="notif in notifications" :key="notif.id" class="py-3 flex items-center justify-between hover:bg-gray-50 cursor-pointer transition px-1 group">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 rounded-full bg-black flex items-center justify-center text-white shrink-0">
              <UserIcon class="w-4 h-4" />
            </div>
            <div>
              <p class="text-xs font-bold text-gray-900 leading-tight">{{ notif.name }}</p>
              <p class="text-[10px] text-gray-500">{{ notif.action }}</p>
              <span class="text-[9px] text-gray-400">{{ notif.time }}</span>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <div v-if="notif.unread" class="w-2 h-2 rounded-full bg-red-500"></div>
            <button
              @click.stop="removeNotification(notif.id)"
              class="p-1 text-gray-400 hover:text-red-500 hover:bg-gray-100 rounded-md transition"
              title="Hapus notifikasi"
            >
              <X class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
        <div v-if="notifications.length === 0" class="py-6 text-center text-xs text-gray-400">
          Tidak ada notifikasi baru
        </div>
      </div>
    </div>

  </div>
</template>