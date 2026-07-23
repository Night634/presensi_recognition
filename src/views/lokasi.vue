<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden relative">
    
    <!-- BACKDROP MOBILE -->
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
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100">
          <div class="flex items-center space-x-3">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs">P</div>
            <span class="font-bold text-sm text-gray-800">Admin Portal</span>
          </div>
          <button @click="isSidebarOpen = false" class="lg:hidden text-gray-500">
            <X class="w-6 h-6" />
          </button>
        </div>
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
            <div v-if="activeMenu === item.name" class="w-1.5 h-6 bg-blue-600 rounded-full"></div>
          </button>
        </nav>
      </div>
      <div class="p-4 border-t border-gray-100">
        <button @click="handleLogout" class="flex items-center space-x-3.5 px-4 py-3 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-xl w-full transition">
          <LogOut class="w-5 h-5" stroke-width="2" />
          <span>Keluar</span>
        </button>
      </div>
    </aside>

    <!-- MAIN CONTAINER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- HEADER -->
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

      <!-- BODY -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        <div>
          <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
          <h1 class="text-2xl font-bold text-gray-950">Wilayah Lokasi Absensi</h1>
        </div>

        <!-- LEAFLET MAP UTAMA -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div ref="mapContainer" class="w-full h-[350px] sm:h-[400px] relative z-0"></div>
        </div>

        <!-- SEARCH & ADD -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
          <div class="relative w-full sm:w-80">
            <input v-model="searchQuery" type="text" placeholder="Cari nama gedung..." class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition shadow-xs" />
            <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          </div>
          <button 
            @click="handleOpenModal()" 
            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl shadow-md shadow-blue-500/20 transition duration-150 text-center"
          >
            + Buat Area Polygon
          </button>
        </div>

        <!-- TABLE DATA LOKASI -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse min-w-[650px]">
              <thead>
                <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-white">
                  <th class="py-4 px-6 text-center w-16">No</th>
                  <th class="py-4 px-6">Nama Gedung</th>
                  <th class="py-4 px-6">Jumlah Titik Sudut</th>
                  <th class="py-4 px-6">Titik Pusat (Center)</th>
                  <th class="py-4 px-6 text-center">Aksi</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 text-sm font-semibold text-gray-900">
                <tr v-for="(item, index) in paginatedLokasi" :key="item.id" class="hover:bg-gray-50/80 transition">
                  <td class="py-4 px-6 text-center">{{ displayFrom + index }}</td>
                  <td class="py-4 px-6">{{ item.nama_gedung }}</td>
                  <td class="py-4 px-6">
                    <span class="bg-blue-50 text-blue-600 px-2.5 py-1 rounded-md text-xs font-bold">
                      {{ item.coordinates ? item.coordinates.length : 0 }} Titik
                    </span>
                  </td>
                  <td class="py-4 px-6 text-xs text-gray-500 font-mono">
                    {{ getCenterCoordinate(item.coordinates) }}
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center justify-center space-x-2">
                      <button 
                        @click="handleFocusMap(item)"
                        class="bg-[#0B1A30] hover:bg-slate-800 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
                      >
                        Lihat
                      </button>
                      <button 
                        @click="handleOpenModal(item)"
                        class="bg-amber-500 hover:bg-amber-600 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
                      >
                        Edit
                      </button>
                      <button 
                        @click="handleDelete(item.id)"
                        class="bg-red-600 hover:bg-red-700 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
                      >
                        Hapus
                      </button>
                    </div>
                  </td>
                </tr>
                <tr v-if="paginatedLokasi.length === 0">
                  <td colspan="5" class="py-8 text-center text-gray-400 text-sm">
                    {{ isLoading ? 'Memuat data...' : 'Belum ada wilayah polygon yang ditambahkan.' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- PAGINATION -->
        <div class="flex flex-col sm:flex-row items-center justify-end gap-4 text-xs font-medium text-gray-600 pt-2">
          <div class="flex items-center space-x-2">
            <span>Halaman:</span>
            <select v-model="currentPage" class="border border-gray-300 rounded-md px-2 py-1 bg-white focus:outline-none text-xs">
              <option v-for="page in totalPages" :key="page" :value="page">{{ page }}</option>
            </select>
          </div>
          <span>{{ displayFrom }} - {{ displayTo }} dari {{ filteredLokasi.length }}</span>
          <div class="flex items-center space-x-1">
            <button @click="goToPrev" :disabled="currentPage === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
              <ChevronLeft class="w-4 h-4" />
            </button>
            <button @click="goToNext" :disabled="currentPage === totalPages" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30">
              <ChevronRight class="w-4 h-4" />
            </button>
          </div>
        </div>
      </main>
    </div>

    <!-- MODAL TAMBAH / EDIT POLYGON -->
    <div 
      v-if="isModalOpen" 
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs transition-opacity overflow-y-auto"
    >
      <div class="bg-white rounded-2xl w-full max-w-3xl p-6 sm:p-8 shadow-2xl relative my-8 border border-gray-100 z-[10000]">
        
        <!-- Modal Header -->
        <div class="text-center mb-4">
          <h2 class="text-xl sm:text-2xl font-bold text-gray-900">{{ isEditMode ? 'Edit Area Polygon' : 'Tambah Area Polygon' }}</h2>
          <p class="text-xs text-gray-500 mt-1">Klik pada peta minimal 3 titik untuk membentuk batas wilayah absensi</p>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <!-- Nama Gedung -->
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Nama Gedung / Area</label>
            <input
              v-model="formLokasi.nama_gedung"
              type="text"
              placeholder="Contoh: Komplek Gedung Utama"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

          <!-- Peta Interaktif Gambar Polygon -->
          <div>
            <div class="flex items-center justify-between mb-1">
              <label class="block text-xs font-semibold text-gray-700">Gambar Polygon di Peta</label>
              <div class="space-x-2">
                <button 
                  type="button" 
                  @click="handleUndoPoint" 
                  :disabled="formLokasi.coordinates.length === 0"
                  class="text-xs text-amber-600 hover:underline font-semibold disabled:opacity-40"
                >
                  ↺ Undo Titik
                </button>
                <button 
                  type="button" 
                  @click="handleResetPoints" 
                  :disabled="formLokasi.coordinates.length === 0"
                  class="text-xs text-red-600 hover:underline font-semibold disabled:opacity-40"
                >
                  ✕ Reset Peta
                </button>
              </div>
            </div>

            <div ref="modalMapContainer" class="w-full h-[300px] rounded-xl overflow-hidden border border-gray-200 relative z-0"></div>
            
            <p class="text-[11px] text-gray-400 mt-1">
              Terpilih: <strong class="text-blue-600">{{ formLokasi.coordinates.length }} titik</strong> 
              <span v-if="formLokasi.coordinates.length < 3" class="text-red-500 ml-1">(butuh minimal 3 titik untuk membuat area)</span>
              <span v-else class="text-green-600 ml-1">✓ Area Valid</span>
            </p>
          </div>

          <!-- List Koordinat Terpilih (Collapsible/Preview) -->
          <div v-if="formLokasi.coordinates.length > 0" class="bg-gray-50 p-3 rounded-lg border border-gray-200 max-h-24 overflow-y-auto">
            <p class="text-[10px] font-bold text-gray-500 uppercase mb-1">Daftar Koordinat [Lat, Lng]:</p>
            <div class="flex flex-wrap gap-1.5">
              <span 
                v-for="(coord, idx) in formLokasi.coordinates" 
                :key="idx"
                class="bg-white border border-gray-200 px-2 py-0.5 rounded text-[10px] font-mono text-gray-700"
              >
                #{{ idx+1 }}: [{{ coord[0] }}, {{ coord[1] }}]
              </span>
            </div>
          </div>

          <!-- Buttons -->
          <div class="flex items-center space-x-3 pt-4">
            <button
              type="submit"
              :disabled="isSubmitting || formLokasi.coordinates.length < 3"
              class="flex-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold py-3 rounded-lg shadow-md transition duration-150 disabled:opacity-50"
            >
              {{ isSubmitting ? 'Menyimpan...' : (isEditMode ? 'Update Polygon' : 'Simpan Polygon') }}
            </button>
            <button
              type="button"
              @click="isModalOpen = false"
              class="flex-1 bg-white hover:bg-gray-50 text-blue-600 border border-blue-600 text-xs font-semibold py-3 rounded-lg transition duration-150"
            >
              Batal
            </button>
          </div>
        </form>

      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import logoSetneg from '../assets/logosetneg.png'
import { 
  LayoutGrid, Users, Scan, CalendarCheck, MapPin, LogOut, Bell, Search, 
  ChevronLeft, ChevronRight, Menu, X, User
} from 'lucide-vue-next'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Fix Leaflet Default Icon
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})

const router = useRouter()
const API_URL = 'http://localhost:8000/api/lokasi'

const getAuthHeader = () => ({
  headers: { Authorization: `Bearer ${sessionStorage.getItem('admin_token')}` }
})

// ===== STATE =====
const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const isModalOpen = ref(false)
const isEditMode = ref(false)
const isLoading = ref(false)
const isSubmitting = ref(false)
const editingId = ref(null)

const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(4)
const activeMenu = ref('Lokasi')

const lokasiList = ref([])

// Map Refs
const mapContainer = ref(null)
const modalMapContainer = ref(null)
let mainMap = null
let modalMap = null
let mainLayers = []
let modalLayers = [] // Menampung marker & polygon sementara di modal

// Form State
const formLokasi = ref({
  nama_gedung: '',
  coordinates: [] // Array of [lat, lng]
})

// Navigation
const navItems = [
  { name: 'Dashboard', icon: LayoutGrid, path: '/dashboard' },
  { name: 'Pegawai', icon: Users, path: '/pegawai' },
  { name: 'Presensi', icon: Scan, path: '/presensi' },
  { name: 'Cuti', icon: CalendarCheck, path: '/cuti' },
  { name: 'Lokasi', icon: MapPin, path: '/lokasi' },
]

const navigateTo = (item) => {
  activeMenu.value = item.name
  isSidebarOpen.value = false
  router.push(item.path)
}

const handleLogout = () => {
  sessionStorage.clear()
  router.replace({ name: 'Login' })
}

// ===== API CRUD =====
const fetchLokasi = async () => {
  isLoading.value = true
  try {
    const response = await axios.get(API_URL, getAuthHeader())
    lokasiList.value = response.data
    renderMainMapPolygons()
  } catch (error) {
    console.error('Gagal mengambil data lokasi:', error)
  } finally {
    isLoading.value = false
  }
}

const handleSubmit = async () => {
  if (formLokasi.value.coordinates.length < 3) {
    alert('Area Polygon membutuhkan minimal 3 titik!')
    return
  }

  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      await axios.put(`${API_URL}/${editingId.value}`, formLokasi.value, getAuthHeader())
    } else {
      await axios.post(API_URL, formLokasi.value, getAuthHeader())
    }
    await fetchLokasi()
    isModalOpen.value = false
  } catch (error) {
    console.error('Gagal menyimpan polygon:', error)
    alert('Gagal menyimpan area polygon!')
  } finally {
    isSubmitting.value = false
  }
}

const handleDelete = async (id) => {
  if (!confirm('Apakah Anda yakin ingin menghapus lokasi ini?')) return
  try {
    await axios.delete(`${API_URL}/${id}`, getAuthHeader())
    await fetchLokasi()
  } catch (error) {
    console.error('Gagal menghapus lokasi:', error)
  }
}

// ===== HELPER FUNCTIONS =====
const getCenterCoordinate = (coords) => {
  if (!coords || coords.length === 0) return '-'
  let sumLat = 0
  let sumLng = 0
  coords.forEach(c => {
    sumLat += parseFloat(c[0])
    sumLng += parseFloat(c[1])
  })
  const avgLat = (sumLat / coords.length).toFixed(5)
  const avgLng = (sumLng / coords.length).toFixed(5)
  return `${avgLat}, ${avgLng}`
}

// ===== COMPUTED =====
const filteredLokasi = computed(() => {
  return lokasiList.value.filter(item => 
    item.nama_gedung.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredLokasi.value.length / pageSize.value)))
const paginatedLokasi = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredLokasi.value.slice(start, start + pageSize.value)
})
const displayFrom = computed(() => filteredLokasi.value.length === 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1)
const displayTo = computed(() => Math.min(filteredLokasi.value.length, currentPage.value * pageSize.value))

watch(searchQuery, () => { currentPage.value = 1 })
const goToPrev = () => { if (currentPage.value > 1) currentPage.value -= 1 }
const goToNext = () => { if (currentPage.value < totalPages.value) currentPage.value += 1 }

// ===== LEAFLET MAP FUNCTIONS =====

// 1. Peta Utama
function initMainMap() {
  if (!mapContainer.value || mainMap) return

  mainMap = L.map(mapContainer.value, {
    center: [-6.2088, 106.8456],
    zoom: 15,
    zoomControl: true
  })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap',
    maxZoom: 19
  }).addTo(mainMap)

  mainMap.whenReady(() => renderMainMapPolygons())
}

function renderMainMapPolygons() {
  if (!mainMap) return

  // Clean old layers
  mainLayers.forEach(layer => mainMap.removeLayer(layer))
  mainLayers = []

  lokasiList.value.forEach(lok => {
    if (lok.coordinates && lok.coordinates.length >= 3) {
      const polygon = L.polygon(lok.coordinates, {
        color: '#3B82F6',
        fillColor: '#3B82F6',
        fillOpacity: 0.25,
        weight: 2
      })
      .bindPopup(`<strong>${lok.nama_gedung}</strong><br/>Jumlah Titik: ${lok.coordinates.length}`)
      .addTo(mainMap)

      mainLayers.push(polygon)
    }
  })
}

// 2. Peta Modal (Drawing Mode)
function initModalMap() {
  nextTick(() => {
    if (!modalMapContainer.value) return

    // Tentukan Center Peta Modal
    let initCenter = [-6.2088, 106.8456]
    if (formLokasi.value.coordinates.length > 0) {
      initCenter = formLokasi.value.coordinates[0]
    }

    modalMap = L.map(modalMapContainer.value, {
      center: initCenter,
      zoom: 16,
      zoomControl: true
    })

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap',
      maxZoom: 19
    }).addTo(modalMap)

    // Render ulang titik yang sudah ada (jika Edit Mode)
    updateModalMapLayers()

    // Event Klik Peta untuk Tambah Titik
    modalMap.on('click', (e) => {
      const lat = parseFloat(e.latlng.lat.toFixed(8))
      const lng = parseFloat(e.latlng.lng.toFixed(8))
      
      formLokasi.value.coordinates.push([lat, lng])
      updateModalMapLayers()
    })

    setTimeout(() => {
      modalMap.invalidateSize()
    }, 300)
  })
}

function updateModalMapLayers() {
  if (!modalMap) return

  // Bersihkan layer sebelumnya di modal
  modalLayers.forEach(l => modalMap.removeLayer(l))
  modalLayers = []

  const coords = formLokasi.value.coordinates

  // 1. Buat Marker untuk setiap titik
  coords.forEach((c, i) => {
    const marker = L.circleMarker(c, {
      radius: 5,
      color: '#2563EB',
      fillColor: '#FFFFFF',
      fillOpacity: 1,
      weight: 2
    }).addTo(modalMap)
    
    modalLayers.push(marker)
  })

  // 2. Jika 2 titik: Gambar Garis (Polyline)
  if (coords.length === 2) {
    const polyline = L.polyline(coords, { color: '#3B82F6', weight: 2, dashArray: '4, 4' }).addTo(modalMap)
    modalLayers.push(polyline)
  }

  // 3. Jika >= 3 titik: Gambar Polygon
  if (coords.length >= 3) {
    const polygon = L.polygon(coords, {
      color: '#3B82F6',
      fillColor: '#3B82F6',
      fillOpacity: 0.3,
      weight: 2
    }).addTo(modalMap)
    
    modalLayers.push(polygon)
  }
}

// Control Buttons Peta Modal
const handleUndoPoint = () => {
  formLokasi.value.coordinates.pop()
  updateModalMapLayers()
}

const handleResetPoints = () => {
  formLokasi.value.coordinates = []
  updateModalMapLayers()
}

// ===== HANDLERS =====
const handleOpenModal = (item = null) => {
  if (item) {
    isEditMode.value = true
    editingId.value = item.id
    formLokasi.value = {
      nama_gedung: item.nama_gedung,
      // Buat deep copy array koordinat
      coordinates: item.coordinates ? JSON.parse(JSON.stringify(item.coordinates)) : []
    }
  } else {
    isEditMode.value = false
    editingId.value = null
    formLokasi.value = { nama_gedung: '', coordinates: [] }
  }
  isModalOpen.value = true
}

const handleFocusMap = (item) => {
  if (mainMap && item.coordinates && item.coordinates.length > 0) {
    const polygon = L.polygon(item.coordinates)
    mainMap.fitBounds(polygon.getBounds(), { padding: [50, 50], maxZoom: 18 })
  }
}

// ===== LIFECYCLE & WATCHERS =====
onMounted(() => {
  fetchLokasi()
  setTimeout(() => initMainMap(), 300)
})

onUnmounted(() => {
  if (mainMap) mainMap.remove()
  if (modalMap) modalMap.remove()
})

watch(isModalOpen, async (val) => {
  if (val) {
    await nextTick()
    setTimeout(() => initModalMap(), 200)
  } else {
    if (modalMap) {
      modalMap.remove()
      modalMap = null
      modalLayers = []
    }
  }
})
</script>