import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

// Helper Cookie Native
const setCookie = (name, value, days) => {
  let expires = ''
  if (days) {
    const date = new Date()
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
    expires = '; expires=' + date.toUTCString()
  }
  document.cookie = name + '=' + (encodeURIComponent(value) || '') + expires + '; path=/'
}

const getCookie = (name) => {
  const nameEQ = name + '='
  const ca = document.cookie.split(';')
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i]
    while (c.charAt(0) === ' ') c = c.substring(1, c.length)
    if (c.indexOf(nameEQ) === 0) return decodeURIComponent(c.substring(nameEQ.length, c.length))
  }
  return null
}

const eraseCookie = (name) => {
  document.cookie = name + '=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;'
}

export function useAdminAuth() {
  const router = useRouter()

  // Ambil token/user fleksibel dari Cookie ATAU sessionStorage
  const getStoredToken = () => getCookie('admin_token') || sessionStorage.getItem('admin_token') || ''
  
  const getStoredUser = () => {
    const u = getCookie('admin_user') || sessionStorage.getItem('admin_user')
    return u ? JSON.parse(u) : null
  }

  const token = ref(getStoredToken())
  const adminUser = ref(getStoredUser())

  const isAuthenticated = computed(() => !!getStoredToken())
  const username = computed(() => {
    const user = adminUser.value || getStoredUser()
    if (!user) return 'Admin'
    return user.nama || user.name || user.nip || 'Admin'
  })

  const getAuthHeader = () => ({
    headers: {
      Authorization: `Bearer ${getStoredToken()}`,
      Accept: 'application/json'
    }
  })

  const setAuthData = (newToken, newUser, rememberMe = false) => {
    token.value = newToken
    adminUser.value = newUser

    // Bersihkan dulu session/cookie lama
    sessionStorage.clear()
    eraseCookie('admin_token')
    eraseCookie('admin_user')

    if (rememberMe) {
      // Simpan di cookie jika "Ingat Saya" dicentang (berlaku 7 hari)
      setCookie('admin_token', newToken, 7)
      setCookie('admin_user', JSON.stringify(newUser), 7)
    } else {
      // Simpan di sessionStorage jika tidak dicentang
      sessionStorage.setItem('admin_token', newToken)
      sessionStorage.setItem('admin_user', JSON.stringify(newUser))
    }
  }

  const handleLogout = async () => {
    try {
      const currentToken = getStoredToken()
      if (currentToken) {
        // Melakukan request ke endpoint logout yang sudah didaftarkan di Laravel
        await axios.post('http://127.0.0.1:8000/api/admin/logout', {}, getAuthHeader()).catch(() => {})
      }
    } finally {
      // Bersihkan semua penyimpanan
      sessionStorage.clear()
      eraseCookie('admin_token')
      eraseCookie('admin_user')

      token.value = ''
      adminUser.value = null

      // Direct balik ke Login
      if (router) {
        router.replace({ name: 'Login' }).catch(() => {
          window.location.href = '/login'
        })
      } else {
        window.location.href = '/login'
      }
    }
  }

  return {
    token,
    adminUser,
    username,
    isAuthenticated,
    getAuthHeader,
    setAuthData,
    handleLogout
  }
}