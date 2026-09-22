<template>
  <div class="flex h-screen bg-[#F0F4F8] font-sans text-gray-900 overflow-hidden relative">
    
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

    <!-- MAIN CONTAINER -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- HEADER -->
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

      <!-- BODY -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 space-y-6">
        <!-- HEADER HALAMAN -->
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <p class="text-xs font-semibold text-gray-400 mb-1">Hello, Admin</p>
            <h1 class="text-2xl font-bold text-gray-950">Wilayah Lokasi Absensi</h1>
          </div>
          <button 
            @click="handleOpenModal()" 
            class="bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm px-6 py-2.5 rounded-xl shadow-md shadow-blue-500/20 transition duration-150 text-center self-start sm:self-auto"
          >
            + Buat Area Polygon Kantor
          </button>
        </div>

        <!-- CONTAINER PETA UTAMA & FILTER -->
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden p-4 space-y-3">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <h2 class="font-bold text-sm text-gray-800">Peta Sebaran Lokasi Presensi</h2>
            
            <!-- FILTER MAP & TABEL -->
            <div class="flex items-center space-x-2">
              <span class="text-xs text-gray-500 font-semibold">Tampilkan Data:</span>
              <select 
                v-model="mapFilter" 
                @change="onFilterChange" 
                class="text-xs border border-gray-200 rounded-lg px-3 py-1.5 bg-gray-50 text-gray-800 font-bold focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">Semua Lokasi (Kantor & Pegawai)</option>
                <option value="kantor">Hanya Lokasi Resmi Kantor</option>
                <option value="pegawai">Hanya Pengajuan Pegawai</option>
              </select>
            </div>
          </div>

          <div ref="mapContainer" class="w-full h-[360px] sm:h-[420px] rounded-xl overflow-hidden relative z-0 border border-gray-100"></div>
        </div>

        <!-- SEARCH BAR -->
        <div class="flex items-center justify-between">
          <div class="relative w-full sm:w-80">
            <input v-model="searchQuery" type="text" placeholder="Cari nama gedung atau pengaju..." class="w-full bg-white border border-gray-200 rounded-xl pl-4 pr-10 py-2.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition shadow-xs" />
            <Search class="w-4 h-4 text-gray-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
          </div>
        </div>

        <!-- TABEL 1: DATA LOKASI KANTOR RESMI -->
        <div v-if="mapFilter === 'all' || mapFilter === 'kantor'" class="space-y-3">
          <div class="flex justify-between items-center px-1">
            <h2 class="font-bold text-base text-gray-900 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-600"></span>
              Lokasi Resmi Kantor
            </h2>
            <span class="text-xs text-gray-500 font-medium">{{ filteredKantor.length }} Gedung Terdaftar</span>
          </div>

          <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse min-w-[650px]">
                <thead>
                  <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-gray-50/50">
                    <th class="py-3.5 px-6 text-center w-16">No</th>
                    <th class="py-3.5 px-6">Nama Gedung</th>
                    <th class="py-3.5 px-6">Tipe Wilayah</th>
                    <th class="py-3.5 px-6">Koordinat Pusat</th>
                    <th class="py-3.5 px-6 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm font-semibold text-gray-900">
                  <tr v-for="(item, index) in paginatedKantor" :key="item.id" class="hover:bg-gray-50/80 transition">
                    <td class="py-4 px-6 text-center text-xs text-gray-500">{{ displayFromKantor + index }}</td>
                    <td class="py-4 px-6 font-bold text-gray-900">{{ item.nama_gedung }}</td>
                    <td class="py-4 px-6">
                      <span v-if="item.tipe === 'radius'" class="bg-amber-100 text-amber-700 px-2.5 py-1 rounded-md text-xs font-bold">
                        Radius {{ item.radius_meter || 30 }}m
                      </span>
                      <span v-else class="bg-blue-50 text-blue-600 px-2.5 py-1 rounded-md text-xs font-bold">
                        Polygon ({{ item.coordinates ? item.coordinates.length : 0 }} Titik)
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
                          class="bg-blue-500 hover:bg-blue-600 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition"
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
                  <tr v-if="paginatedKantor.length === 0">
                    <td colspan="5" class="py-8 text-center text-gray-400 text-sm">
                      {{ isLoading ? 'Memuat data...' : 'Tidak ada data lokasi kantor.' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- PAGINATION TABEL KANTOR -->
          <div v-if="filteredKantor.length > 0" class="flex items-center justify-end space-x-3 text-xs text-gray-600 pt-1">
            <span>{{ displayFromKantor }} - {{ displayToKantor }} dari {{ filteredKantor.length }}</span>
            <div class="flex items-center space-x-1">
              <button @click="currentPageKantor--" :disabled="currentPageKantor === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
                <ChevronLeft class="w-4 h-4" />
              </button>
              <button @click="currentPageKantor++" :disabled="currentPageKantor === totalPagesKantor" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30">
                <ChevronRight class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- TABEL 2: DATA PENGAJUAN PEGAWAI MOBILE -->
        <div v-if="mapFilter === 'all' || mapFilter === 'pegawai'" class="space-y-3 pt-2">
          <div class="flex justify-between items-center px-1">
            <h2 class="font-bold text-base text-gray-900 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
              Pengajuan Lokasi Pegawai (Mobile)
            </h2>
            <div class="flex items-center space-x-3">
              <span v-if="pendingCount > 0" class="bg-red-500 text-white text-xs font-bold px-2.5 py-0.5 rounded-full">
                {{ pendingCount }} Perlu Approval
              </span>
              <button @click="fetchPengajuan" class="text-xs text-blue-600 font-bold hover:underline">
                ↻ Refresh
              </button>
            </div>
          </div>

          <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse min-w-[700px]">
                <thead>
                  <tr class="border-b border-gray-100 text-xs font-bold text-gray-800 bg-gray-50/50">
                    <th class="py-3.5 px-6">Nama Pengaju</th>
                    <th class="py-3.5 px-6">Nama Usulan Gedung</th>
                    <th class="py-3.5 px-6">Koordinat Titik</th>
                    <th class="py-3.5 px-6">Status</th>
                    <th class="py-3.5 px-6 text-center">Aksi Approval</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-sm font-semibold text-gray-900">
                  <tr v-for="item in paginatedPegawai" :key="item.id" class="hover:bg-gray-50/80 transition">
                    <td class="py-4 px-6">
                      <div class="text-gray-900 font-bold">{{ item.nama_pengaju }}</div>
                      <div class="text-xs text-gray-400 font-mono">NIP: {{ item.nip_pengaju || '-' }}</div>
                    </td>
                    <td class="py-4 px-6 font-bold text-gray-800">{{ item.nama_gedung }}</td>
                    <td class="py-4 px-6 text-xs text-gray-500 font-mono">
                      {{ item.latitude }}, {{ item.longitude }}
                    </td>
                    <td class="py-4 px-6">
                      <span :class="{
                        'bg-amber-100 text-amber-700': item.status === 'pending',
                        'bg-emerald-100 text-emerald-700': item.status === 'approved',
                        'bg-red-100 text-red-700': item.status === 'rejected'
                      }" class="px-2.5 py-1 rounded-md text-xs font-bold uppercase">
                        {{ item.status }}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-center">
                      <div class="flex items-center justify-center space-x-2">
                        <button 
                          @click="openPreviewModal(item)"
                          class="bg-slate-800 hover:bg-slate-900 text-white text-xs font-semibold px-3 py-1.5 rounded-md transition shadow-xs"
                        >
                          Lihat Peta
                        </button>

                        <template v-if="item.status === 'pending'">
                          <button 
                            @click="handleApprove(item.id)" 
                            class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-3 py-1.5 rounded-md transition shadow-xs"
                          >
                            Approve
                          </button>
                          <button 
                            @click="handleReject(item.id)" 
                            class="bg-red-600 hover:bg-red-700 text-white text-xs font-bold px-3 py-1.5 rounded-md transition shadow-xs"
                          >
                            Tolak
                          </button>
                        </template>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="paginatedPegawai.length === 0">
                    <td colspan="5" class="py-8 text-center text-gray-400 text-sm">
                      Belum ada data pengajuan dari pegawai.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- PAGINATION TABEL PEGAWAI -->
          <div v-if="filteredPegawai.length > 0" class="flex items-center justify-end space-x-3 text-xs text-gray-600 pt-1">
            <span>{{ displayFromPegawai }} - {{ displayToPegawai }} dari {{ filteredPegawai.length }}</span>
            <div class="flex items-center space-x-1">
              <button @click="currentPagePegawai--" :disabled="currentPagePegawai === 1" class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
                <ChevronLeft class="w-4 h-4" />
              </button>
              <button @click="currentPagePegawai++" :disabled="currentPagePegawai === totalPagesPegawai" class="p-1 text-gray-600 hover:text-gray-900 disabled:opacity-30">
                <ChevronRight class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

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
              <User class="w-4 h-4" />
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

    <!-- MODAL POPUP PETA PREVIEW PENGAJUAN -->
    <div 
      v-if="isPreviewModalOpen" 
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs transition-opacity"
    >
      <div class="bg-white rounded-2xl w-full max-w-xl overflow-hidden shadow-2xl relative border border-gray-100 z-[10000]">
        <div class="p-4 border-b border-slate-800 bg-slate-900 text-white flex justify-between items-center">
          <div>
            <h3 class="font-bold text-sm">{{ selectedPengajuan?.nama_gedung }}</h3>
            <p class="text-xs text-slate-300">Pengaju: <b>{{ selectedPengajuan?.nama_pengaju }}</b> (NIP: {{ selectedPengajuan?.nip_pengaju || '-' }})</p>
          </div>
          <button @click="closePreviewModal" class="text-white hover:text-red-400 font-bold text-xl leading-none">&times;</button>
        </div>

        <div class="p-4 space-y-3">
          <div ref="previewMapContainer" class="w-full h-[320px] rounded-xl overflow-hidden border border-gray-200 relative z-0"></div>

          <div class="flex justify-between items-center text-xs text-gray-600 bg-gray-50 p-3 rounded-xl border border-gray-100 font-medium">
            <span>Radius Absensi: <b class="text-blue-600">30 Meter</b></span>
            <span>Koordinat: <b class="font-mono text-gray-800">{{ selectedPengajuan?.latitude }}, {{ selectedPengajuan?.longitude }}</b></span>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL TAMBAH / EDIT POLYGON KANTOR -->
    <div 
      v-if="isModalOpen" 
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs transition-opacity overflow-y-auto"
    >
      <div class="bg-white rounded-2xl w-full max-w-3xl p-6 sm:p-8 shadow-2xl relative my-8 border border-gray-100 z-[10000]">
        <div class="text-center mb-4">
          <h2 class="text-xl sm:text-2xl font-bold text-gray-900">{{ isEditMode ? 'Edit Area Polygon Kantor' : 'Tambah Area Polygon Kantor' }}</h2>
          <p class="text-xs text-gray-500 mt-1">Klik pada peta minimal 3 titik untuk membentuk batas wilayah absensi kantor</p>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-700 mb-1">Nama Gedung / Area</label>
            <input
              v-model="formLokasi.nama_gedung"
              type="text"
              placeholder="Contoh: Gedung Sekretariat Negara"
              class="w-full bg-gray-200/80 border-none rounded-lg px-3.5 py-2.5 text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              required
            />
          </div>

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

<style>
.leaflet-div-icon.custom-map-pin-marker {
  background: transparent !important;
  border: none !important;
}
</style>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import logoSetneg from '../assets/logosetneg.png'
import { useNotifications } from '../composables/useNotifications'
import { useAdminAuth } from '../composables/useAdminAuth'
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
const API_URL = 'http://127.0.0.1:8000/api/lokasi'

const { getAuthHeader, handleLogout } = useAdminAuth()

// ===== STATE UTAMA =====
const mapFilter = ref('all') // 'all', 'kantor', 'pegawai'
const searchQuery = ref('')
const pengajuanList = ref([])
const lokasiList = ref([])

const isSidebarOpen = ref(false)
const isNotifOpen = ref(false)
const isModalOpen = ref(false)
const isEditMode = ref(false)
const isLoading = ref(false)
const isSubmitting = ref(false)
const editingId = ref(null)

const isPreviewModalOpen = ref(false)
const selectedPengajuan = ref(null)

// Pagination State
const currentPageKantor = ref(1)
const currentPagePegawai = ref(1)
const pageSize = ref(4)

const activeMenu = ref('Lokasi')
const { notifications, fetchNotifications, removeNotification, clearAllNotif } = useNotifications()

const toggleNotifications = async () => {
  isNotifOpen.value = !isNotifOpen.value
  if (isNotifOpen.value) await fetchNotifications()
}

// Map Container Refs & Instances
const mapContainer = ref(null)
const modalMapContainer = ref(null)
const previewMapContainer = ref(null)

let mainMap = null
let modalMap = null
let previewMap = null

let mainLayers = []
let modalLayers = []

const formLokasi = ref({
  nama_gedung: '',
  coordinates: []
})

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

// ===== API FETCH DATA =====
const fetchPengajuan = async () => {
  try {
    const response = await axios.get(`${API_URL}/pengajuan-list`, getAuthHeader())
    pengajuanList.value = response.data
    renderMainMapPolygons()
  } catch (error) {
    console.error('Gagal mengambil data pengajuan:', error)
  }
}

const fetchLokasi = async () => {
  isLoading.value = true
  try {
    const response = await axios.get(API_URL, getAuthHeader())
    lokasiList.value = response.data.map(item => ({
      ...item,
      coordinates: normalizeCoordinates(item.coordinates)
    }))
    renderMainMapPolygons()
  } catch (error) {
    console.error('Gagal mengambil data lokasi:', error)
  } finally {
    isLoading.value = false
  }
}

// ===== APPROVAL HANDLERS =====
const handleApprove = async (id) => {
  if (!confirm('Setujui pengajuan lokasi ini? Lokasi akan langsung aktif di sistem.')) return
  try {
    await axios.post(`${API_URL}/pengajuan/${id}/approve`, {}, getAuthHeader())
    await fetchPengajuan()
    await fetchLokasi()
    alert('Pengajuan berhasil disetujui!')
  } catch (error) {
    console.error('Gagal memproses approval:', error)
    alert('Gagal menyetujui pengajuan.')
  }
}

const handleReject = async (id) => {
  const alasan = prompt('Masukkan alasan penolakan:')
  if (alasan === null) return
  try {
    await axios.post(`${API_URL}/pengajuan/${id}/reject`, { alasan }, getAuthHeader())
    await fetchPengajuan()
  } catch (error) {
    console.error('Gagal menolak pengajuan:', error)
  }
}

// ===== CRUD KANTOR HANDLERS =====
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
  if (!confirm('Apakah Anda yakin ingin menghapus lokasi kantor ini?')) return
  try {
    await axios.delete(`${API_URL}/${id}`, getAuthHeader())
    await fetchLokasi()
  } catch (error) {
    console.error('Gagal menghapus lokasi:', error)
  }
}

// ===== HELPER FUNCTIONS =====
const normalizeCoordinates = (raw) => {
  if (!raw) return []
  try {
    let coords = raw
    if (typeof coords === 'string') coords = JSON.parse(coords)
    if (!Array.isArray(coords)) return []

    if (coords.length > 0 && Array.isArray(coords[0]) && Array.isArray(coords[0][0])) {
      return coords[0].map(pt => [parseFloat(pt[1]), parseFloat(pt[0])]).filter(p => !isNaN(p[0]) && !isNaN(p[1]))
    }

    if (coords.length > 0 && typeof coords[0][0] === 'number' && typeof coords[0][1] === 'number') {
      return coords.map(pt => [parseFloat(pt[0]), parseFloat(pt[1])]).filter(p => !isNaN(p[0]) && !isNaN(p[1]))
    }

    return []
  } catch (e) {
    return []
  }
}

const getCenterCoordinate = (coords) => {
  const arr = normalizeCoordinates(coords)
  if (!arr || arr.length === 0) return '-'
  let sumLat = 0
  let sumLng = 0
  arr.forEach(c => {
    sumLat += parseFloat(c[0])
    sumLng += parseFloat(c[1])
  })
  const avgLat = (sumLat / arr.length).toFixed(5)
  const avgLng = (sumLng / arr.length).toFixed(5)
  return `${avgLat}, ${avgLng}`
}

// ===== COMPUTED (FILTER & PAGINATION UNTUK 2 TABEL) =====
const pendingCount = computed(() => pengajuanList.value.filter(p => p.status === 'pending').length)

// Filter Lokasi Kantor
const filteredKantor = computed(() => {
  return lokasiList.value.filter(item => 
    item.nama_gedung.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})
const totalPagesKantor = computed(() => Math.max(1, Math.ceil(filteredKantor.value.length / pageSize.value)))
const paginatedKantor = computed(() => {
  const start = (currentPageKantor.value - 1) * pageSize.value
  return filteredKantor.value.slice(start, start + pageSize.value)
})
const displayFromKantor = computed(() => filteredKantor.value.length === 0 ? 0 : (currentPageKantor.value - 1) * pageSize.value + 1)
const displayToKantor = computed(() => Math.min(filteredKantor.value.length, currentPageKantor.value * pageSize.value))

// Filter Pengajuan Pegawai
const filteredPegawai = computed(() => {
  const q = searchQuery.value.toLowerCase()
  return pengajuanList.value.filter(item => 
    (item.nama_gedung && item.nama_gedung.toLowerCase().includes(q)) ||
    (item.nama_pengaju && item.nama_pengaju.toLowerCase().includes(q))
  )
})
const totalPagesPegawai = computed(() => Math.max(1, Math.ceil(filteredPegawai.value.length / pageSize.value)))
const paginatedPegawai = computed(() => {
  const start = (currentPagePegawai.value - 1) * pageSize.value
  return filteredPegawai.value.slice(start, start + pageSize.value)
})
const displayFromPegawai = computed(() => filteredPegawai.value.length === 0 ? 0 : (currentPagePegawai.value - 1) * pageSize.value + 1)
const displayToPegawai = computed(() => Math.min(filteredPegawai.value.length, currentPagePegawai.value * pageSize.value))

watch(searchQuery, () => {
  currentPageKantor.value = 1
  currentPagePegawai.value = 1
})

const onFilterChange = () => {
  renderMainMapPolygons()
}

// ===== LEAFLET MAP UTAMA =====
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

const areaColors = [
  { border: '#2563EB', fill: '#3B82F6' },
  { border: '#059669', fill: '#10B981' },
  { border: '#7C3AED', fill: '#8B5CF6' },
  { border: '#0891B2', fill: '#06B6D4' },
]

function renderMainMapPolygons() {
  if (!mainMap) return

  mainLayers.forEach(layer => mainMap.removeLayer(layer))
  mainLayers = []

  const boundsGroup = []

  // 1. Gambar Lokasi Resmi Kantor
  if (mapFilter.value === 'all' || mapFilter.value === 'kantor') {
    lokasiList.value.forEach((lok, index) => {
      const coords = normalizeCoordinates(lok.coordinates)
      if (coords && coords.length >= 3) {
        const colorScheme = areaColors[index % areaColors.length]

        const polygon = L.polygon(coords, {
          color: colorScheme.border,
          fillColor: colorScheme.fill,
          fillOpacity: 0.35,
          weight: 3
        })
        .bindPopup(`
          <div class="p-1 font-sans">
            <strong class="text-sm text-gray-900 block font-bold mb-0.5">[Kantor Resmi] ${lok.nama_gedung}</strong>
            <span class="text-xs text-gray-500">Polygon Wilayah Presensi</span>
          </div>
        `)
        .addTo(mainMap)

        mainLayers.push(polygon)

        const center = polygon.getBounds().getCenter()
        boundsGroup.push(polygon.getBounds())

        // Marker Pin Kantor
        const customIcon = L.divIcon({
          className: 'custom-map-pin-marker',
          html: `
            <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; transform: translate(-50%, -50%); pointer-events: none;">
              <div style="background: #FFFFFF; padding: 5px; border-radius: 9999px; box-shadow: 0 4px 10px rgba(0,0,0,0.25); border: 2px solid ${colorScheme.border}; display: flex; align-items: center; justify-content: center;">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="${colorScheme.border}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"></path>
                  <circle cx="12" cy="10" r="3"></circle>
                </svg>
              </div>
              <div style="margin-top: 3px; background: #0F172A; color: #FFFFFF; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; box-shadow: 0 2px 6px rgba(0,0,0,0.3); font-family: ui-sans-serif, system-ui, sans-serif;">
                ${lok.nama_gedung}
              </div>
            </div>
          `,
          iconSize: [0, 0],
          iconAnchor: [0, 0]
        })

        const labelMarker = L.marker(center, { icon: customIcon, interactive: false }).addTo(mainMap)
        mainLayers.push(labelMarker)
      }
    })
  }

  // 2. Gambar Pengajuan Pegawai (DENGAN NAMA PENGAJU DI MAP)
  if (mapFilter.value === 'all' || mapFilter.value === 'pegawai') {
    pengajuanList.value.forEach(item => {
      const lat = parseFloat(item.latitude)
      const lng = parseFloat(item.longitude)

      if (!isNaN(lat) && !isNaN(lng)) {
        const isApproved = item.status === 'approved'
        const isPending = item.status === 'pending'
        const statusColor = isApproved ? '#10B981' : (isPending ? '#F59E0B' : '#EF4444')

        // Circle Radius
        const circle = L.circle([lat, lng], {
          color: statusColor,
          fillColor: statusColor,
          fillOpacity: 0.35,
          radius: item.radius_meter || 30
        })
        .bindPopup(`
          <div class="p-1 font-sans">
            <strong class="text-sm text-gray-900 block font-bold mb-0.5">${item.nama_gedung}</strong>
            <p class="text-xs text-gray-600 mb-1">Pengaju: <b>${item.nama_pengaju}</b></p>
            <span class="text-[10px] font-bold uppercase px-2 py-0.5 rounded ${isApproved ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'}">Status: ${item.status}</span>
          </div>
        `)
        .addTo(mainMap)

        mainLayers.push(circle)
        boundsGroup.push(circle.getBounds())

        // Marker Pin Pegawai + Label Nama Pengaju (Contoh: "Farul")
        const pegawaiIcon = L.divIcon({
          className: 'custom-map-pin-marker',
          html: `
            <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; transform: translate(-50%, -50%); pointer-events: none;">
              <div style="background: ${statusColor}; color: white; width: 26px; height: 26px; border-radius: 9999px; box-shadow: 0 3px 8px rgba(0,0,0,0.3); border: 2px solid #FFFFFF; display: flex; items-center; justify-content: center; font-weight: bold; font-size: 12px;">
                👤
              </div>
              <div style="margin-top: 3px; background: #FFFFFF; color: #0F172A; border: 1.5px solid ${statusColor}; font-size: 10px; font-weight: 800; padding: 2px 6px; border-radius: 6px; white-space: nowrap; box-shadow: 0 2px 6px rgba(0,0,0,0.15); font-family: ui-sans-serif, system-ui, sans-serif;">
                ${item.nama_pengaju || 'Pegawai'} (${item.nama_gedung})
              </div>
            </div>
          `,
          iconSize: [0, 0],
          iconAnchor: [0, 0]
        })

        const labelMarker = L.marker([lat, lng], { icon: pegawaiIcon, interactive: false }).addTo(mainMap)
        mainLayers.push(labelMarker)
      }
    })
  }

  if (boundsGroup.length > 0) {
    const featureGroup = L.featureGroup(mainLayers)
    mainMap.fitBounds(featureGroup.getBounds(), { padding: [40, 40] })
  }
}

// ===== POPUP MODAL PETA PREVIEW PENGAJUAN PEGAWAI =====
const openPreviewModal = (item) => {
  selectedPengajuan.value = item
  isPreviewModalOpen.value = true

  nextTick(() => {
    setTimeout(() => {
      if (previewMapContainer.value) {
        if (previewMap) previewMap.remove()

        const lat = parseFloat(item.latitude)
        const lng = parseFloat(item.longitude)

        previewMap = L.map(previewMapContainer.value).setView([lat, lng], 18)

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; OpenStreetMap',
          maxZoom: 19
        }).addTo(previewMap)

        L.marker([lat, lng]).addTo(previewMap)
          .bindPopup(`<b>${item.nama_gedung}</b><br>Pengaju: ${item.nama_pengaju}`).openPopup()

        L.circle([lat, lng], {
          color: '#2563EB',
          fillColor: '#3B82F6',
          fillOpacity: 0.35,
          radius: item.radius_meter || 30
        }).addTo(previewMap)

        setTimeout(() => previewMap.invalidateSize(), 200)
      }
    }, 150)
  })
}

const closePreviewModal = () => {
  isPreviewModalOpen.value = false
  if (previewMap) {
    previewMap.remove()
    previewMap = null
  }
}

// ===== MODAL LEAFLET BUAT/EDIT POLYGON KANTOR =====
function initModalMap() {
  nextTick(() => {
    if (!modalMapContainer.value) return

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

    updateModalMapLayers()

    modalMap.on('click', (e) => {
      const lat = parseFloat(e.latlng.lat.toFixed(8))
      const lng = parseFloat(e.latlng.lng.toFixed(8))
      formLokasi.value.coordinates.push([lat, lng])
      updateModalMapLayers()
    })

    setTimeout(() => { modalMap.invalidateSize() }, 300)
  })
}

function updateModalMapLayers() {
  if (!modalMap) return

  modalLayers.forEach(l => modalMap.removeLayer(l))
  modalLayers = []

  const coords = formLokasi.value.coordinates

  coords.forEach((c) => {
    const marker = L.circleMarker(c, {
      radius: 5,
      color: '#2563EB',
      fillColor: '#FFFFFF',
      fillOpacity: 1,
      weight: 2
    }).addTo(modalMap)
    modalLayers.push(marker)
  })

  if (coords.length === 2) {
    const polyline = L.polyline(coords, { color: '#3B82F6', weight: 2, dashArray: '4, 4' }).addTo(modalMap)
    modalLayers.push(polyline)
  }

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

const handleUndoPoint = () => {
  formLokasi.value.coordinates.pop()
  updateModalMapLayers()
}

const handleResetPoints = () => {
  formLokasi.value.coordinates = []
  updateModalMapLayers()
}

const handleOpenModal = (item = null) => {
  if (item) {
    isEditMode.value = true
    editingId.value = item.id
    formLokasi.value = {
      nama_gedung: item.nama_gedung,
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

// ===== LIFECYCLE =====
onMounted(() => {
  fetchLokasi()
  fetchPengajuan()
  fetchNotifications()
  setTimeout(() => initMainMap(), 300)
})

onUnmounted(() => {
  if (mainMap) mainMap.remove()
  if (modalMap) modalMap.remove()
  if (previewMap) previewMap.remove()
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