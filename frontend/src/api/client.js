const UNPAK_AUTH_API = '/unpak-api'; // proxied to https://hrportal.unpak.ac.id/api/v2
const LOCAL_API_BASE = '';           // proxied to http://localhost:3000

export const apiClient = {
  getToken() {
    const raw = localStorage.getItem('token') || localStorage.getItem('hrportal_token') || '';
    if (!raw || raw === 'null' || raw === 'undefined') return '';
    const parts = raw.split('.');
    if (parts.length !== 3) return '';
    return raw;
  },

  getHeaders(isFormData = false) {
    const token = this.getToken();
    const headers = {};
    if (!isFormData) {
      headers['Content-Type'] = 'application/json';
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  },

  resolveUrl(endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    // Route login and whoami requests to https://hrportal.unpak.ac.id/api/v2
    const lower = endpoint.toLowerCase();
    if (lower.includes('/account/login') || lower.includes('/login') || lower.includes('/whoami')) {
      // Clean path if it has /api/v2 prefix
      const cleanPath = endpoint.replace(/^\/api\/v2/, '').replace(/^\/api/, '');
      return `${UNPAK_AUTH_API}${cleanPath.startsWith('/') ? cleanPath : '/' + cleanPath}`;
    }
    // All other endpoints go to localhost:3000
    return `${LOCAL_API_BASE}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;
  },

  async request(endpoint, options = {}) {
    const url = this.resolveUrl(endpoint);
    const isFormData = options.body instanceof FormData || options.isFormData;
    
    const config = {
      ...options,
      headers: {
        ...this.getHeaders(isFormData),
        ...(options.headers || {}),
      },
    };

    try {
      const response = await fetch(url, config);
      
      if (response.status === 401 && !endpoint.includes('login')) {
        // Token expired or invalid
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.dispatchEvent(new Event('auth-logout'));
        throw new Error('Sesi login telah berakhir. Silakan login kembali.');
      }

      const contentType = response.headers.get('content-type') || '';
      
      let data;
      const text = await response.text();

      if (contentType.includes('text/event-stream') || text.startsWith('total:') || text.includes('event: start') || text.includes('data: {') || text.includes('data:{"')) {
        const list = [];
        const lines = text.split('\n');
        for (const line of lines) {
          const trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            const jsonStr = trimmed.substring(5).trim();
            if (jsonStr) {
              try {
                list.push(JSON.parse(jsonStr));
              } catch (e) {
                console.warn('Failed to parse SSE line JSON:', jsonStr);
              }
            }
          }
        }
        data = list;
      } else if (contentType.includes('application/json')) {
        try {
          data = JSON.parse(text);
        } catch {
          data = text;
        }
      } else {
        try {
          data = JSON.parse(text);
        } catch {
          data = text;
        }
      }

      if (!response.ok) {
        const errorMsg = data?.message || data?.error || `Request failed with status ${response.status}`;
        throw new Error(errorMsg);
      }

      return data;
    } catch (err) {
      console.error(`[API Error] ${endpoint} -> ${url}:`, err);
      throw err;
    }
  },

  get(endpoint, params = {}) {
    const query = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        query.append(key, value);
      }
    });
    const queryString = query.toString();
    const finalUrl = queryString ? `${endpoint}?${queryString}` : endpoint;
    return this.request(finalUrl, { method: 'GET' });
  },

  post(endpoint, body = {}) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(body),
    });
  },

  postForm(endpoint, formData) {
    const form = new URLSearchParams();
    Object.entries(formData).forEach(([k, v]) => {
      if (v !== undefined && v !== null) {
        form.append(k, v);
      }
    });
    return this.request(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
  },

  put(endpoint, body = {}) {
    return this.request(endpoint, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  },

  putForm(endpoint, formData) {
    const form = new URLSearchParams();
    Object.entries(formData).forEach(([k, v]) => {
      if (v !== undefined && v !== null) {
        form.append(k, v);
      }
    });
    return this.request(endpoint, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
  },

  delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' });
  },

  async downloadBlob(endpoint, defaultFilename = 'download.csv') {
    const url = this.resolveUrl(endpoint);
    const token = this.getToken();
    const headers = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    const response = await fetch(url, {
      method: 'GET',
      headers,
    });
    if (!response.ok) {
      let errMsg = `Download failed with status ${response.status}`;
      try {
        const errJson = await response.json();
        errMsg = errJson.message || errJson.error || errMsg;
      } catch {}
      throw new Error(errMsg);
    }

    let filename = defaultFilename;
    const disposition = response.headers.get('Content-Disposition') || '';
    if (disposition.includes('filename=')) {
      const match = disposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
      if (match && match[1]) {
        filename = match[1].replace(/['"]/g, '').trim();
      }
    }

    const blob = await response.blob();
    const objectUrl = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = objectUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(objectUrl);
  },
};
