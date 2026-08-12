import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/unpak-api': {
        target: 'https://hrportal.unpak.ac.id/api/v2',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/unpak-api/, ''),
        secure: false,
      },
      '/unpak-sso-token': {
        target: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/token',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/unpak-sso-token/, ''),
        secure: false,
      },
      '/unpak-masterdata': {
        target: 'https://hrportal.unpak.ac.id/api/masterdata',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/unpak-masterdata/, ''),
        secure: false,
      },
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
      },
      '/ws': {
        target: 'ws://127.0.0.1:3000',
        ws: true,
      },
    },
  },
});
