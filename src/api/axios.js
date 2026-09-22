import axios from 'axios';
import Cookies from 'js-cookie';

const api = axios.create({
  baseURL: 'http://localhost:8000/api', // sesuaikan dengan URL backend kamu
});

// Request Interceptor: Otomatis tempel token di Header
api.interceptors.request.use(
  (config) => {
    // Cari token di Cookies dulu, kalau tidak ada baru cek sessionStorage
    const token = Cookies.get('token') || sessionStorage.getItem('token');

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default api;