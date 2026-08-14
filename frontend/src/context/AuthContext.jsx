import React, { createContext, useContext, useState, useEffect } from 'react';
import { apiClient } from '../api/client';

const AuthContext = createContext(null);

export const SSO_CONFIG = {
  authUrl: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/auth',
  tokenUrl: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/token',
  clientId: 'unpak_link_gate',
  redirectUri: window.location.origin + '/login',
};

export const decodeJwt = (token) => {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return {};
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(payload)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    console.error('Failed to decode JWT:', e);
    return {};
  }
};

export const isSdmAuthorized = (userInfo) => {
  if (!userInfo || typeof userInfo !== 'object') return false;
  const { level, role, name, groups = [], realmRoles = [] } = userInfo;
  const normLevel = (level || '').toLowerCase();
  const normRole = (role || '').toLowerCase();
  const normName = (name || '').toLowerCase();

  // Local admin / sdm check
  if (
    normLevel === 'sdm' ||
    normLevel === 'admin' ||
    normLevel === 'baum' ||
    normRole === 'sdm' ||
    normRole === 'admin' ||
    normName === 'sdm'
  ) {
    return true;
  }

  // Keycloak SSO Group or Realm Role checks (sdm, baum, inherit_sdm, inherit_baum, adm_pusat)
  const allowedGroups = ['sdm', 'baum', 'inherit_sdm', 'inherit_baum', 'adm_pusat'];
  const safeGroups = Array.isArray(groups) ? groups : [];
  const safeRoles = Array.isArray(realmRoles) ? realmRoles : [];
  const allGroups = [
    ...safeGroups.map((g) => (typeof g === 'string' ? g.toLowerCase() : '')),
    ...safeRoles.map((r) => (typeof r === 'string' ? r.toLowerCase() : '')),
  ];

  return allGroups.some((g) => allowedGroups.includes(g));
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem('token') || '');
  const [loading, setLoading] = useState(true);

  const logout = () => {
    setUser(null);
    setToken('');
    localStorage.removeItem('token');
    localStorage.removeItem('refresh');
    localStorage.removeItem('user');
    window.location.href = '/login';
  };

  useEffect(() => {
    const handleLogout = () => {
      setUser(null);
      setToken('');
    };
    window.addEventListener('auth-logout', handleLogout);
    return () => window.removeEventListener('auth-logout', handleLogout);
  }, []);

  useEffect(() => {
    // Validate & hydrate session from localStorage
    const initAuth = async () => {
      const savedToken = localStorage.getItem('token');
      const savedUser = localStorage.getItem('user');
      if (savedToken && savedUser) {
        try {
          const parsedUser = JSON.parse(savedUser);
          if (parsedUser) {
            if (!parsedUser.level) parsedUser.level = 'sdm';
            if (!parsedUser.role) parsedUser.role = 'sdm';
            setUser(parsedUser);
            setToken(savedToken);
          }
        } catch (e) {
          console.warn('Error parsing saved user from localStorage:', e);
        }
      }
      setLoading(false);
    };
    initAuth();
  }, []);

  const saveAuthSession = (authToken, refreshToken, userInfo) => {
    setToken(authToken);
    setUser(userInfo);
    localStorage.setItem('token', authToken);
    if (refreshToken) {
      localStorage.setItem('refresh', refreshToken);
    }
    localStorage.setItem('user', JSON.stringify(userInfo));
  };

  const fetchWhoAmI = async (authToken) => {
    try {
      const res = await apiClient.get('/account/whoami');
      if (res) {
        setUser((currentUser) => {
          const baseUser = currentUser || {};
          const updatedUser = {
            ...baseUser,
            name: res.name || baseUser.name || 'SDM User',
            email: res.email || baseUser.email || '',
            username: res.nip || res.sid || baseUser.username || '',
            nip: res.nip || baseUser.nip || '',
            nidn: res.nidn || baseUser.nidn || '',
            role: res.level || res.role || baseUser.role || 'sdm',
            level: res.level || baseUser.level || 'sdm',
            fakultas: res.fakultas || baseUser.fakultas || '',
            prodi: res.prodi || baseUser.prodi || '',
            unit: res.unit || baseUser.unit || '',
            groups: baseUser.groups || [],
            realmRoles: baseUser.realmRoles || [],
            isSso: baseUser.isSso || false,
          };
          localStorage.setItem('user', JSON.stringify(updatedUser));
          return updatedUser;
        });
      }
    } catch (e) {
      console.warn('Gagal memperbarui data profil whoami:', e);
    }
  };

  const loginRegular = async (usernameInput, passwordInput) => {
    try {
      const res = await apiClient.postForm('/api/v2/account/login', {
        username: usernameInput,
        password: passwordInput,
      });

      const authToken = res.token || res.access_token || '';
      const refreshToken = res.refresh || res.refresh_token || '';

      if (!authToken) {
        return { success: false, error: res.message || 'Token tidak diterima dari server' };
      }

      const decoded = decodeJwt(authToken);
      const userInfo = {
        name: decoded.name || res.name || usernameInput,
        email: decoded.email || res.email || '',
        username: usernameInput,
        nip: res.nip || usernameInput,
        nidn: res.nidn || '-',
        role: decoded.level || res.level || 'sdm',
        level: decoded.level || res.level || 'sdm',
      };

      if (decoded.employeeid) {
        userInfo.employeeId = decoded.employeeid || userInfo.nip;
      }

      if (!isSdmAuthorized(userInfo)) {
        return { 
          success: false, 
          error: 'Akses Ditolak: Akun Anda tidak memiliki hak akses Administrator SDM (SDM/BAUM/ADM_HR).' 
        };
      }

      saveAuthSession(authToken, refreshToken, userInfo);
      fetchWhoAmI(authToken);
      return { success: true, user: userInfo };
    } catch (err) {
      return { success: false, error: err.message };
    }
  };

  const exchangeSsoCode = async (code) => {
    try {
      const origin = window.location.origin;
      const redirectUri = `${origin}/login`;

      const body = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: SSO_CONFIG.clientId,
        code: code,
        redirect_uri: redirectUri,
      });

      let response;
      try {
        response = await fetch('/unpak-sso-token', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: body.toString(),
        });
      } catch (e) {
        response = await fetch(SSO_CONFIG.tokenUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: body.toString(),
        });
      }

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`SSO Exchange Gagal (${response.status}): ${errText}`);
      }

      const tokenData = await response.json();
      const accessToken = tokenData.access_token;
      const refreshToken = tokenData.refresh_token || '';
      const idToken = tokenData.id_token || '';

      if (!accessToken) {
        throw new Error('Access Token tidak ditemukan dalam respon SSO');
      }

      const tokenToDecode = idToken || accessToken;
      const decoded = decodeJwt(tokenToDecode);

      const name = decoded.name || decoded.preferred_username || decoded.employeeid || 'User SSO';
      const email = decoded.email || '';
      const employeeId = decoded.employeeid || decoded.sub || '-';
      const groups = Array.isArray(decoded.group) ? decoded.group : [];
      const realmRoles = decoded.realm_access?.roles || [];

      const userInfo = {
        name,
        email,
        username: employeeId,
        nip: employeeId,
        nidn: '-',
        role: 'sdm',
        level: 'sdm',
        groups,
        realmRoles,
        isSso: true,
      };

      if (!isSdmAuthorized(userInfo)) {
        return {
          success: false,
          error: 'Akses Ditolak: Akun SSO Anda tidak berada dalam grup SDM / BAUM / ADM_HR / INHERIT_SDM / INHERIT_BAUM.',
        };
      }

      saveAuthSession(accessToken, refreshToken, userInfo);
      fetchWhoAmI(accessToken);
      return { success: true, user: userInfo };
    } catch (err) {
      console.error('SSO Code Exchange Error:', err);
      return { success: false, error: err.message || 'Gagal bertukar kode SSO Keycloak' };
    }
  };

  const loginWithSsoToken = (accessToken, idToken) => {
    try {
      const tokenToDecode = idToken || accessToken;
      const decoded = decodeJwt(tokenToDecode);
      
      const name = decoded.name || decoded.preferred_username || 'User SSO';
      const email = decoded.email || '';
      const employeeId = decoded.employeeid || decoded.sub || '-';
      const groups = Array.isArray(decoded.group) ? decoded.group : [];
      const realmRoles = decoded.realm_access?.roles || [];

      const userInfo = {
        name,
        email,
        username: employeeId,
        nip: employeeId,
        nidn: '-',
        role: 'sdm',
        level: 'sdm',
        groups,
        realmRoles,
        isSso: true,
      };

      if (!isSdmAuthorized(userInfo)) {
        return {
          success: false,
          error: 'Akses Ditolak: Akun SSO Anda tidak berada dalam grup SDM / BAUM / ADM_HR / INHERIT_SDM / INHERIT_BAUM.',
        };
      }

      saveAuthSession(accessToken, '', userInfo);
      fetchWhoAmI(accessToken);
      return { success: true, user: userInfo };
    } catch (err) {
      console.error('SSO Token Login Error:', err);
      return { success: false, error: err.message };
    }
  };

  const triggerSsoRedirect = () => {
    const origin = window.location.origin;
    const redirectUri = `${origin}/login`;
    const url = `${SSO_CONFIG.authUrl}?client_id=${SSO_CONFIG.clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=openid`;
    console.log('Redirecting to UNPAK Keycloak SSO:', url);
    window.location.href = url;
  };

  const value = {
    user,
    token,
    loading,
    isAuthenticated: !!token && !!user,
    isSdm: isSdmAuthorized(user),
    loginRegular,
    exchangeSsoCode,
    loginWithSsoToken,
    triggerSsoRedirect,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
