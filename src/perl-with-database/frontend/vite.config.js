import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: process.env.services__api__https__0 || process.env.services__api__http__0 || 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
