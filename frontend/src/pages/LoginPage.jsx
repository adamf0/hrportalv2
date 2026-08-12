import React, { useState, useEffect } from 'react';
import { 
  Building2, 
  Lock, 
  User, 
  ArrowRight, 
  ShieldCheck, 
  Sparkles,
  AlertCircle,
  LogIn
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';

export const LoginPage = () => {
  const { loginRegular, exchangeSsoCode, loginWithSsoToken, triggerSsoRedirect } = useAuth();
  const { showToast } = useToast();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const hasExchangedRef = React.useRef(false);

  // Handle SSO Callback Code or Token from URL parameters
  useEffect(() => {
    const handleSsoCallback = async () => {
      const search = window.location.search;
      const hash = window.location.hash;
      const params = new URLSearchParams(search || (hash ? hash.substring(1) : ''));
      const code = params.get('code');
      const accessToken = params.get('access_token');
      const idToken = params.get('id_token');

      if (code && !hasExchangedRef.current) {
        hasExchangedRef.current = true;
        window.history.replaceState({}, document.title, window.location.pathname);

        setLoading(true);
        setErrorMessage('');
        showToast('Memproses autentikasi Unpak SSO Keycloak...', 'info');
        const res = await exchangeSsoCode(code);
        if (res.success) {
          showToast(`Selamat datang, ${res.user.name}! (Unpak SSO)`, 'success');
          window.history.pushState(null, '', '/dashboard');
        } else {
          setErrorMessage(res.error || 'Gagal login via Unpak SSO');
          showToast(res.error || 'Gagal login via Unpak SSO', 'error');
        }
        setLoading(false);
      } else if (accessToken && !hasExchangedRef.current) {
        hasExchangedRef.current = true;
        window.history.replaceState({}, document.title, window.location.pathname);

        setLoading(true);
        setErrorMessage('');
        const res = loginWithSsoToken(accessToken, idToken);
        if (res.success) {
          showToast('Login dengan Unpak SSO berhasil!', 'success');
          window.history.pushState(null, '', '/dashboard');
        } else {
          setErrorMessage(res.error || 'Gagal login via SSO');
          showToast(res.error || 'Gagal login via SSO', 'error');
        }
        setLoading(false);
      }
    };

    handleSsoCallback();
  }, []);

  const handleRegularLogin = async (e) => {
    e.preventDefault();
    if (!username.trim() || !password.trim()) {
      setErrorMessage('Harap isi Username / NIP dan Password.');
      return;
    }

    setLoading(true);
    setErrorMessage('');

    const res = await loginRegular(username.trim(), password.trim());
    if (res.success) {
      showToast(`Selamat datang, ${res.user.name}!`, 'success');
      window.history.pushState(null, '', '/dashboard');
    } else {
      setErrorMessage(res.error || 'Login gagal. Periksa kembali NIP/Password Anda.');
      showToast(res.error || 'Login gagal', 'error');
    }
    setLoading(false);
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'radial-gradient(circle at 20% 20%, #f3e8ff 0%, #f8fafc 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Background Decorative Blur Blobs */}
      <div
        style={{
          position: 'absolute',
          top: '-10%',
          left: '-5%',
          width: '500px',
          height: '500px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(168,85,247,0.15) 0%, rgba(255,255,255,0) 70%)',
          filter: 'blur(40px)',
          zIndex: 0,
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: '-10%',
          right: '-5%',
          width: '500px',
          height: '500px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(147,51,234,0.12) 0%, rgba(255,255,255,0) 70%)',
          filter: 'blur(40px)',
          zIndex: 0,
        }}
      />

      <div
        className="animate-fade-in"
        style={{
          width: '100%',
          maxWidth: '440px',
          backgroundColor: '#ffffff',
          borderRadius: '24px',
          boxShadow: '0 20px 40px -15px rgba(147,51,234,0.12), 0 0 1px 1px rgba(0,0,0,0.05)',
          padding: '40px 36px',
          position: 'relative',
          zIndex: 1,
          border: '1px solid rgba(243,232,255,0.8)',
        }}
      >
        {/* Logo & Header */}
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div
            style={{
              width: '64px',
              height: '64px',
              borderRadius: '20px',
              background: 'linear-gradient(135deg, var(--color-primary) 0%, #7e22ce 100%)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 10px 20px -5px rgba(147,51,234,0.4)',
              marginBottom: '16px',
            }}
          >
            <Building2 size={32} color="#ffffff" />
          </div>
          <h1
            style={{
              fontSize: '1.65rem',
              fontWeight: 800,
              color: 'var(--text-main)',
              letterSpacing: '-0.025em',
              marginBottom: '6px',
            }}
          >
            HR Portal SDM
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
            Universitas Pakuan - Panel Manajemen SDM
          </p>
        </div>

        {/* Error Alert Message */}
        {errorMessage && (
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-start',
              gap: '10px',
              padding: '12px 14px',
              borderRadius: '12px',
              backgroundColor: '#fef2f2',
              border: '1px solid #fecaca',
              color: '#dc2626',
              fontSize: '0.825rem',
              marginBottom: '20px',
            }}
          >
            <AlertCircle size={18} style={{ flexShrink: 0, marginTop: '1px' }} />
            <div>{errorMessage}</div>
          </div>
        )}

        {/* Primary Action: UNPAK KEYCLOAK SSO LOGIN BUTTON */}
        <button
          type="button"
          onClick={triggerSsoRedirect}
          disabled={loading}
          style={{
            width: '100%',
            padding: '14px 20px',
            borderRadius: '14px',
            border: 'none',
            background: 'linear-gradient(135deg, var(--color-primary) 0%, #6b21a8 100%)',
            color: '#ffffff',
            fontSize: '0.95rem',
            fontWeight: 800,
            cursor: loading ? 'not-allowed' : 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '10px',
            boxShadow: '0 8px 16px -4px rgba(147,51,234,0.35)',
            transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
            marginBottom: '24px',
          }}
          onMouseEnter={(e) => {
            if (!loading) e.currentTarget.style.transform = 'translateY(-2px)';
          }}
          onMouseLeave={(e) => {
            if (!loading) e.currentTarget.style.transform = 'translateY(0)';
          }}
        >
          <Sparkles size={20} />
          <span>{loading ? 'Memproses SSO...' : 'Login dengan Unpak SSO'}</span>
          <ArrowRight size={18} style={{ marginLeft: 'auto' }} />
        </button>

        {/* Divider */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            margin: '24px 0',
            gap: '12px',
          }}
        >
          <div style={{ flex: 1, height: '1px', backgroundColor: 'var(--border-light)' }} />
          <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
            Atau Login Lokal / NIP
          </span>
          <div style={{ flex: 1, height: '1px', backgroundColor: 'var(--border-light)' }} />
        </div>

        {/* Secondary Action: REGULAR NIP & PASSWORD LOGIN FORM */}
        <form onSubmit={handleRegularLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label
              htmlFor="username-input"
              style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: '6px' }}
            >
              NIP / Username SDM
            </label>
            <div style={{ position: 'relative' }}>
              <User
                size={18}
                color="var(--text-muted)"
                style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }}
              />
              <input
                id="username-input"
                type="text"
                className="form-input"
                placeholder="Masukkan NIP atau Username..."
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                style={{ paddingLeft: '42px', borderRadius: '12px' }}
                disabled={loading}
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="password-input"
              style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-main)', marginBottom: '6px' }}
            >
              Password
            </label>
            <div style={{ position: 'relative' }}>
              <Lock
                size={18}
                color="var(--text-muted)"
                style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }}
              />
              <input
                id="password-input"
                type="password"
                className="form-input"
                placeholder="Masukkan Password..."
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ paddingLeft: '42px', borderRadius: '12px' }}
                disabled={loading}
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px 18px',
              borderRadius: '12px',
              border: '1px solid var(--border-light)',
              backgroundColor: '#f8fafc',
              color: 'var(--text-main)',
              fontSize: '0.875rem',
              fontWeight: 700,
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              marginTop: '8px',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => {
              if (!loading) e.currentTarget.style.backgroundColor = '#f1f5f9';
            }}
            onMouseLeave={(e) => {
              if (!loading) e.currentTarget.style.backgroundColor = '#f8fafc';
            }}
          >
            <LogIn size={16} />
            <span>Masuk dengan NIP/Password</span>
          </button>
        </form>

        {/* Footer Security Badge */}
        <div
          style={{
            marginTop: '32px',
            paddingTop: '20px',
            borderTop: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '6px',
            color: 'var(--text-muted)',
            fontSize: '0.75rem',
          }}
        >
          <ShieldCheck size={16} color="var(--color-primary)" />
          <span>Sistem Terintegrasi SSO & RBAC Universitas Pakuan</span>
        </div>
      </div>
    </div>
  );
};
