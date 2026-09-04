import React, { createContext, useContext, useState, useEffect } from 'react';
import { apiClient } from '../api/client';

const AuthContext = createContext(null);

export const SSO_CONFIG = {
  authUrl: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/auth',
  tokenUrl: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/token',
  logoutUrl: 'https://gerbang.unpak.ac.id/realms/gateway/protocol/openid-connect/logout',
  clientId: 'unpak_link_gate',
  get redirectUri() {
    return "http://gerbang.unpak.ac.id";
  },
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

export const getUserRole = (userInfo) => {
  if (!userInfo || typeof userInfo !== 'object') return 'tendik';
  const { level, role, groups = [], realmRoles = [] } = userInfo;
  const normLevel = (level || '').toLowerCase();
  const normRole = (role || '').toLowerCase();

  const safeGroups = Array.isArray(groups) ? groups : [];
  const safeRoles = Array.isArray(realmRoles) ? realmRoles : [];
  const allGroups = [
    ...safeGroups.map((g) => (typeof g === 'string' ? g.toLowerCase() : '')),
    ...safeRoles.map((r) => (typeof r === 'string' ? r.toLowerCase() : '')),
  ];

  let detectedRole = 'tendik';

  if (normLevel === 'sdm' || normRole === 'sdm') {
    detectedRole = 'sdm';
  } else if (normLevel === 'baum' || normRole === 'baum') {
    detectedRole = 'baum';
  } else if (normLevel === 'dosen' || normRole === 'dosen') {
    detectedRole = 'dosen';
  } else if (normLevel === 'tendik' || normRole === 'tendik' || normRole === 'pegawai') {
    detectedRole = 'tendik';
  } else if (allGroups.some((g) => ['sdm', 'inherit_sdm', 'adm_hr'].includes(g) || g.includes('sdm_'))) {
    detectedRole = 'sdm';
  } else if (allGroups.some((g) => ['baum', 'inherit_baum'].includes(g) || g.includes('baum_'))) {
    detectedRole = 'baum';
  } else if (allGroups.some((g) => g.includes('dosen'))) {
    detectedRole = 'dosen';
  }

  // Validate active_role override against available roles
  const activeOverride = localStorage.getItem('active_role');
  if (activeOverride && ['sdm', 'baum', 'dosen', 'tendik'].includes(activeOverride.toLowerCase())) {
    const available = getAvailableRoles(userInfo);
    if (available.includes(activeOverride.toLowerCase())) {
      return activeOverride.toLowerCase();
    }
  }

  return detectedRole;
};

export const getAvailableRoles = (userInfo) => {
  let userObj = userInfo;
  if (!userObj || typeof userObj !== 'object') {
    try {
      const savedUser = localStorage.getItem('user');
      if (savedUser) userObj = JSON.parse(savedUser);
    } catch (e) {}
  }

  let profileObj = null;
  try {
    const savedProf = localStorage.getItem('profile');
    if (savedProf) profileObj = JSON.parse(savedProf);
  } catch (e) {}

  const collectGroups = [];

  if (userObj) {
    if (Array.isArray(userObj.groups)) collectGroups.push(...userObj.groups);
    else if (typeof userObj.groups === 'string') collectGroups.push(...userObj.groups.split(/[\s,]+/));

    if (Array.isArray(userObj.realmRoles)) collectGroups.push(...userObj.realmRoles);
    if (userObj.level) collectGroups.push(userObj.level);
    if (userObj.role) collectGroups.push(userObj.role);
  }

  if (profileObj) {
    if (Array.isArray(profileObj.groups)) collectGroups.push(...profileObj.groups);
    else if (typeof profileObj.groups === 'string') collectGroups.push(...profileObj.groups.split(/[\s,]+/));

    if (Array.isArray(profileObj.realmRoles)) collectGroups.push(...profileObj.realmRoles);
    if (profileObj.level) collectGroups.push(profileObj.level);
    if (profileObj.role) collectGroups.push(profileObj.role);
  }

  const normGroups = collectGroups.map((g) => (typeof g === 'string' ? g.toLowerCase().trim().replace(/^\//, '') : ''));

  const availableSet = new Set();

  normGroups.forEach((g) => {
    if (!g) return;
    if (g === 'sdm' || g === 'inherit_sdm' || g === 'adm_hr' || g.includes('sdm_') || g.endsWith('_sdm')) {
      availableSet.add('sdm');
    }
    if (g === 'baum' || g === 'inherit_baum' || g.includes('baum_') || g.endsWith('_baum')) {
      availableSet.add('baum');
    }
    if (g === 'dosen' || g.includes('dosen')) {
      availableSet.add('dosen');
    }
    if (g === 'tendik' || g.includes('tendik') || g.includes('pegawai')) {
      availableSet.add('tendik');
    }
  });

  if (availableSet.size === 0) {
    availableSet.add('tendik');
  }

  return Array.from(availableSet);
};

export const canSwitchRole = (userInfo) => {
  const roles = getAvailableRoles(userInfo);
  return roles.length > 1;
};

export const isUserAuthorized = (userInfo) => {
  if (!userInfo || typeof userInfo !== 'object') return false;
  // Allow all logged in users (SDM, Dosen, Tendik) to access HR Portal Panel
  return true;
};

export const isSdmAuthorized = (userInfo) => {
  return getUserRole(userInfo) === 'sdm';
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem('token') || '');
  const [loading, setLoading] = useState(true);

  const logout = () => {
    const savedIdToken = localStorage.getItem('id_token') || '';
    const isSsoUser = user?.isSso || !!savedIdToken || (user && user.groups && user.groups.length > 0);

    setUser(null);
    setToken('');
    localStorage.removeItem('token');
    localStorage.removeItem('refresh');
    localStorage.removeItem('id_token');
    localStorage.removeItem('user');
    localStorage.removeItem('profile');
    localStorage.removeItem('whoami');
    localStorage.removeItem('user_profile');
    localStorage.removeItem('active_role');

    if (isSsoUser) {
      const currentOrigin = window.location.origin;
      const redirectUri = encodeURIComponent(`${currentOrigin}/login`);
      let keycloakLogoutUrl = `${SSO_CONFIG.logoutUrl}?client_id=${SSO_CONFIG.clientId}&post_logout_redirect_uri=${redirectUri}`;
      if (savedIdToken) {
        keycloakLogoutUrl += `&id_token_hint=${encodeURIComponent(savedIdToken)}`;
      }
      window.location.href = keycloakLogoutUrl;
    } else {
      window.location.href = '/login';
    }
  };

  useEffect(() => {
    const handleLogout = () => {
      logout();
    };
    window.addEventListener('auth-logout', handleLogout);
    return () => window.removeEventListener('auth-logout', handleLogout);
  }, []);

  useEffect(() => {
    const initAuth = async () => {
      const savedToken = localStorage.getItem('token');
      const savedUser = localStorage.getItem('user');
      if (savedToken && savedUser) {
        try {
          const parsedUser = JSON.parse(savedUser);
          if (parsedUser) {
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

  const saveAuthSession = (authToken, refreshToken, userInfo, idToken = '') => {
    setToken(authToken);
    setUser(userInfo);
    localStorage.setItem('token', authToken);
    if (refreshToken) {
      localStorage.setItem('refresh', refreshToken);
    }
    if (idToken) {
      localStorage.setItem('id_token', idToken);
    }
    localStorage.setItem('user', JSON.stringify(userInfo));
  };

  const fetchWhoAmI = async (authToken) => {
    try {
      const res = await apiClient.get('/api/v2/account/whoami');
      if (res) {
        localStorage.removeItem('whoami');
        localStorage.removeItem('user_profile');
        localStorage.setItem('profile', JSON.stringify(res));
        setUser((currentUser) => {
          const baseUser = currentUser || {};
          const detectedRole = res.level || res.role || baseUser.role || 'tendik';
          const updatedUser = {
            ...baseUser,
            name: res.name || baseUser.name || 'Pengguna HR Portal',
            email: res.email || baseUser.email || '',
            username: res.nip || res.sid || baseUser.username || '',
            nip: res.nip || baseUser.nip || '',
            nidn: res.nidn || baseUser.nidn || '',
            role: detectedRole,
            level: detectedRole,
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

  const loginRegular = async (usernameInput, passwordInput, selectedRole = 'sdm') => {
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
      const roleAssigned = decoded.level || res.level || selectedRole || 'sdm';
      const userInfo = {
        name: decoded.name || res.name || usernameInput,
        email: decoded.email || res.email || '',
        username: usernameInput,
        nip: res.nip || usernameInput,
        nidn: res.nidn || '-',
        role: roleAssigned,
        level: roleAssigned,
      };

      if (decoded.employeeid) {
        userInfo.employeeId = decoded.employeeid || userInfo.nip;
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

      const response = await fetch(SSO_CONFIG.tokenUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString(),
      });

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

      const tempUser = { groups, realmRoles, level: decoded.level || decoded.role };
      const role = getUserRole(tempUser);

      const userInfo = {
        name,
        email,
        username: employeeId,
        nip: employeeId,
        nidn: '-',
        role: role,
        level: role,
        groups,
        realmRoles,
        isSso: true,
      };

      saveAuthSession(accessToken, refreshToken, userInfo, idToken);
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

      const tempUser = { groups, realmRoles, level: decoded.level || decoded.role };
      const role = getUserRole(tempUser);

      const userInfo = {
        name,
        email,
        username: employeeId,
        nip: employeeId,
        nidn: '-',
        role: role,
        level: role,
        groups,
        realmRoles,
        isSso: true,
      };

      saveAuthSession(accessToken, '', userInfo, idToken);
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
    window.location.href = url;
  };

  const [activeRoleOverride, setActiveRoleOverride] = useState(() => localStorage.getItem('active_role') || null);

  const switchRole = (newRole) => {
    const norm = (newRole || 'tendik').toLowerCase();
    setActiveRoleOverride(norm);
    localStorage.setItem('active_role', norm);

    setUser((prev) => {
      if (!prev) return prev;
      const updated = { ...prev, role: norm, level: norm };
      localStorage.setItem('user', JSON.stringify(updated));
      return updated;
    });

    try {
      const savedProf = localStorage.getItem('profile');
      if (savedProf) {
        const prof = JSON.parse(savedProf);
        prof.level = norm;
        prof.role = norm;
        localStorage.setItem('profile', JSON.stringify(prof));
      }
    } catch (e) {}

    window.dispatchEvent(new CustomEvent('role-changed', { detail: norm }));
  };

  const userRole = activeRoleOverride || getUserRole(user);
  const isSdm = userRole === 'sdm';
  const isBaum = userRole === 'baum';
  const isDosen = userRole === 'dosen';
  const isTendik = userRole === 'tendik';

  const value = {
    user,
    token,
    loading,
    isAuthenticated: !!token && !!user,
    userRole,
    isSdm,
    isBaum,
    isDosen,
    isTendik,
    availableRoles: getAvailableRoles(user),
    canSwitchRole: canSwitchRole(user),
    switchRole,
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
