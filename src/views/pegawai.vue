<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import logoSetneg from '../assets/logosetneg.png'
import { 
  LayoutGrid, 
  Users, 
  Scan, 
  CalendarCheck, 
  LogOut, 
  Bell, 
  Search, 
  ArrowUpDown, 
  Camera, 
  ChevronLeft, 
  ChevronRight,
  User,
  Menu,
  X
} from 'lucide-vue-next'

const router = useRouter()

onMounted(() => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  if (!isAuthenticated) {
    router.push({ name: 'Login' })
  }
})

// State Sidebar Mobile
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)

// State Modal & Form Tambah Pegawai
const isModalOpen = ref(false)
const formPegawai = ref({
  nip: '',
  nama: '',
  email: '',
  posisi: '',
  foto: null
})
const kameraAktif = ref(false)
const videoStream = ref(null)
const videoRef = ref(null)
const canvasRef = ref(null)
const cameraFrame = ref(null)
const fotoPreview = ref(null)

// State Search & Table Data
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(4)
const activeMenu = ref('Pegawai')

const pegawaiList = ref([
  { id: 1, nama: 'Muh Fahrul Fahrezi', nip: '315720393', posisi: 'Staff', dataWajah: 'Image.jpg' },
  { id: 2, nama: 'Muh Fahrul Fahrezi', nip: '315720393', posisi: 'Staff', dataWajah: 'Image.jpg' },
  { id: 3, nama: 'Muh Fahrul Fahrezi', nip: '315720393', posisi: 'Staff', dataWajah: 'Image.jpg' },
  { id: 4, nama: 'Muh Fahrul Fahrezi', nip: '315720393', posisi: 'Staff', dataWajah: 'Image.jpg' },
  { id: 5, nama: 'Ramzy Atchallah Putra', nip: '315720834', posisi: 'Staff', dataWajah: 'Image.jpg' },
])

const notifications = ref([
  { id: 1, name: 'Muh Fahrul', action: 'Mengajukan Cuti', time: '0 min', unread: true },
  { id: 2, name: 'Ramzy', action: 'Terlambat Presensi', time: '6 min', unread: true },
  { id: 3, name: 'Atchallah', action: 'Mengajukan Cuti', time: '15 min', unread: false },
  { id: 4, name: 'Putra', action: 'Mengajukan Cuti', time: '16 min', unread: false },
  { id: 5, name: 'thejoeswanson', action: 'High fived your workout', time: '18 min', unread: true },
])

const clearAllNotif = () => {
  notifications.value = []
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
    alert('Kamera tidak tersedia di perangkat ini.')
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
    alert('Tidak dapat mengakses kamera. Pastikan izin sudah diberikan.')
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

const resetForm = () => {
  formPegawai.value = {
    nip: '',
    nama: '',
    email: '',
    posisi: '',
    foto: null
  }
  fotoPreview.value = null
  stopCamera()
}

onUnmounted(() => {
  stopCamera()
})

// Filter data pegawai berdasarkan pencarian
const filteredPegawai = computed(() => {
  return pegawaiList.value.filter(p => 
    p.nama.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    p.nip.includes(searchQuery.value) ||
    p.posisi.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredPegawai.value.length / pageSize.value)))
const paginatedPegawai = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredPegawai.value.slice(start, start + pageSize.value)
})
const displayFrom = computed(() => filteredPegawai.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredPegawai.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => {
  currentPage.value = 1
})

const goToPrevPegawai = () => {
  if (currentPage.value > 1) currentPage.value -= 1
}

const goToNextPegawai = () => {
  if (currentPage.value < totalPages.value) currentPage.value += 1
}

// Navigation Items
const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, route: 'Dashboard' },
  { name: 'Pegawai', icon: Users, route: 'Pegawai' },
  { name: 'Presensi', icon: Scan, route: 'Presensi' },
  { name: 'Cuti', icon: CalendarCheck, route: 'Cuti' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push({ name: item.route })
}

// Actions
const handleOpenModal = () => {
  resetForm()
  isModalOpen.value = true
}

const handleCloseModal = () => {
  isModalOpen.value = false
  stopCamera()
}

const handleTambahData = () => {
  if (formPegawai.value.nama && formPegawai.value.nip) {
    pegawaiList.value.push({
      id: pegawaiList.value.length + 1,
      nama: formPegawai.value.nama,
      nip: formPegawai.value.nip,
      posisi: formPegawai.value.posisi,
      dataWajah: 'Image.jpg'
    })
    handleCloseModal()
  }
}

const handleDelete = (id) => {
  pegawaiList.value = pegawaiList.value.filter(p => p.id !== id)
}

const handleLogout = () => {
  localStorage.removeItem('isAuthenticated')
  localStorage.removeItem('username')
  router.push({ name: 'Login' })
}
</script>

<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden">
    
    <!-- BACKDROP MOBILE SIDEBAR -->
    <div 
      v-if="isSidebarOpen" 
      @click="isSidebarOpen = false"
      class="fixed inset-0 bg-black/40 backdrop-blur-xs z-40 lg:hidden"
    ></div>

    <!-- SIDEBAR -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 w-64 bg-white border-r border-gray-200 flex flex-col justify-between z-40 transition-transform duration-300 ease-in-out shrink-0',
        isSidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0'
      ]"
    >
      <div>
        <!-- Spacer / Logo Header Sidebar -->
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="isSidebarOpen = false" class="lg:hidden text-gray-500">
            <X class="w-6 h-6" />
          </button>
        </div>

        <!-- Navigation List -->
        <nav class="mt-4 px-4 space-y-1.5">
          <button
            v-for="item in navItems"
            :key="item.name"
            @click="navigateTo(item)"
            :class="[
              'w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-150',
              activeMenu === item.name 
                ? 'text-blue-600 bg-blue-50/60 font-semibold' 
                : 'text-gray-600 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center space-x-3.5">
              <component 
                :is="item.icon" 
                :class="['w-5 h-5', activeMenu === item.name ? 'text-blue-600' : 'text-gray-500']" 
                stroke-width="2"
              />
              <span class="text-sm">{{ item.name }}</span>
            </div>
            <!-- Indicator Line -->
            <div v-if="activeMenu === item.name" class="w-1.5 h-6 bg-blue-600 rounded-full"></div>
          </button>
        </nav>
      </div>

      <!-- Logout Button -->
      <div class="p-4 border-t border-gray-100">
        <button @click="handleLogout" class="flex items-center space-x-3.5 px-4 py-3 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-xl w-full transition">
          <LogOut class="w-5 h-5" stroke-width="2" />
          <span>Keluar</span>
        </button>
      </div>
    </aside>

    <!-- MAIN WRAPPER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      
      <!-- HEADER NAVBAR -->
      <header class="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-8 z-30 shrink-0">
        <div class="flex items-center space-x-3">
          <button @click="isSidebarOpen = true" class="p-2 -ml-2 text-gray-600 lg:hidden">
            <Menu class="w-6 h-6" />
          </button>
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-white flex items-center justify-center">
              <img :src="logoSetneg" alt="Logo Setneg" class="w-full h-full object-cover" />
            </div>
            <span class="font-bold text-xs uppercase tracking-wide text-gray-800">Kementerian Sekretariat Negara Republik Indonesia</span>
          </div>
        </div>
        <button @click="isNotifOpen = !isNotifOpen" class="p-2 text-gray-700 hover:bg-gray-100 rounded-full transition relative">
          <Bell class="w-6 h-6" />
        </button>
      </header>

      <!-- MAIN PAGE CONTENT -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        
        <!-- Welcome Title -->
        <div>
          <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
          <h1 class="text-2xl font-bold text-gray-950">Welcome to List Pegawai!</h1>
        </div>

        <!-- Search Bar & Add Button -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <div class="relative w-full sm:w-80">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search..."
              class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition shadow-xs"
            />
            <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          </div>
          <button
            @click="handleOpenModal"
            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl shadow-md shadow-blue-500/20 transition duration-150 text-center"
          >
            Add
          </button>
        </div>

        <!-- TABLE DATA PEGAWAI -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[650px]">
              <thead>
                <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-white">
                  <th class="py-4 px-6 text-center w-16">No</th>
                  <th class="py-4 px-6">
                    <div class="flex items-center space-x-1.5 cursor-pointer">
                      <span>Nama</span>
                      <ArrowUpDown class="w-3.5 h-3.5 text-gray-400" />
                    </div>
                  </th>
                  <th class="py-4 px-6">NIP</th>
                  <th class="py-4 px-6">Posisi</th>
                  <th class="py-4 px-6">Data Wajah</th>
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
                  <td class="py-4 px-6 text-gray-900 font-semibold">{{ pegawai.nama }}</td>
                  <td class="py-4 px-6 text-gray-900 font-semibold">{{ pegawai.nip }}</td>
                  <td class="py-4 px-6 text-gray-900 font-semibold">{{ pegawai.posisi }}</td>
                  <td class="py-4 px-6 text-gray-900 font-semibold">{{ pegawai.dataWajah }}</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center justify-center space-x-2">
                      <button class="bg-[#0B1A30] hover:bg-slate-800 text-white text-xs font-semibold px-4 py-1.5 rounded-md transition">Edit</button>
                      <button 
                        @click="handleDelete(pegawai.id)"
                        class="bg-red-600 hover:bg-red-700 text-white text-xs font-semibold px-4 py-1.5 rounded-md transition"
                      >Delete</button>
                    </div>
                  </td>
                </tr>

                <tr v-if="paginatedPegawai.length === 0">
                  <td colspan="6" class="py-8 text-center text-gray-400 text-sm">Tidak ada data pegawai yang ditemukan.</td>
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
      </main>
    </div>

    <!-- MODAL TAMBAH PEGAWAI -->
    <div 
      v-if="isModalOpen" 
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs transition-opacity overflow-y-auto"
    >
      <div class="bg-white rounded-2xl w-full max-w-lg p-6 sm:p-8 shadow-2xl relative my-8 border border-gray-100">
        
        <!-- Modal Header -->
        <div class="text-center mb-6">
          <h2 class="text-xl sm:text-2xl font-bold text-gray-900">Tambah Pegawai</h2>
          <p class="text-xs text-gray-500 mt-1">Isi detail yang diperlukan untuk menambahkan karyawan.</p>
        </div>

        <!-- Form Modal -->
        <form @submit.prevent="handleTambahData" class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">NIP</label>
            <input
              v-model="formPegawai.nip"
              type="text"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Nama Pegawai</label>
            <input
              v-model="formPegawai.nama"
              type="text"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

          <!-- Input Email -->
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Email</label>
            <input
              v-model="formPegawai.email"
              type="email"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

          <!-- Input Posisi -->
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Posisi</label>
            <input
              v-model="formPegawai.posisi"
              type="text"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

          <!-- Area Ambil Gambar Muka -->
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Ambil Gambar Muka</label>
            <div class="bg-gray-500 rounded-2xl h-52 flex items-center justify-center relative overflow-hidden">
              <canvas ref="canvasRef" class="w-full h-full object-cover"></canvas>
              <video ref="videoRef" class="hidden" autoplay muted playsinline></video>
              <div v-if="!kameraAktif && !fotoPreview" class="absolute inset-0 flex items-center justify-center">
                <div class="w-16 h-12 bg-gray-300 rounded-lg flex items-center justify-center shadow-xs">
                  <Camera class="w-8 h-8 text-gray-600" />
                </div>
              </div>
              <div v-if="!kameraAktif && fotoPreview" class="absolute inset-0">
                <img :src="fotoPreview" alt="Preview Foto" class="w-full h-full object-cover" />
              </div>

              <button
                type="button"
                @click="kameraAktif ? capturePhoto() : startCamera()"
                class="absolute bottom-4 bg-white hover:bg-gray-100 text-blue-600 border border-blue-600 text-xs font-semibold px-4 py-1.5 rounded-lg shadow-xs transition"
              >
                {{ kameraAktif ? 'Capture' : 'Ambil Gambar' }}
              </button>
            </div>
          </div>

          <!-- Modal Action Buttons -->
          <div class="flex items-center space-x-3 pt-4">
            <button
              type="submit"
              class="flex-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold py-3 rounded-lg shadow-md transition duration-150"
            >
              Tambah Data
            </button>
            <button
              type="button"
              @click="handleCloseModal"
              class="flex-1 bg-white hover:bg-gray-50 text-blue-600 border border-blue-600 text-xs font-semibold py-3 rounded-lg transition duration-150"
            >
              Batal
            </button>
          </div>
        </form>

      </div>
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
        <div v-for="notif in notifications" :key="notif.id" class="py-3 flex items-center justify-between hover:bg-gray-50 cursor-pointer transition px-1">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 rounded-full bg-black flex items-center justify-center text-white shrink-0">
              <User class="w-4 h-4" />
            </div>
            <div>
              <p class="text-xs font-bold text-gray-900 leading-tight">{{ notif.name }}</p>
              <p class="text-[10px] text-gray-500">{{ notif.action }}</p>
              <span class="text-[9px] text-gray-400">{{ notif.time }}</span>
            </div>
          </div>
          <div class="flex items-center space-x-1">
            <div v-if="notif.unread" class="w-2 h-2 rounded-full bg-red-500"></div>
            <ChevronRight class="w-4 h-4 text-gray-400" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>