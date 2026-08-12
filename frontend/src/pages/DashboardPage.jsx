import React, { useState, useEffect, useRef } from 'react';
import { 
  FileCheck, 
  CalendarClock, 
  PlaneTakeoff, 
  CalendarDays, 
  Sparkles,
  RefreshCw,
  ArrowRight,
  Clock
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { Badge } from '../components/Badge';
import { formatTanggalIndo, formatRentangTanggalIndo } from '../utils/date';

export const DashboardPage = ({ onNavigate }) => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [isWsConnected, setIsWsConnected] = useState(false);
  const wsRef = useRef(null);

  const [stats, setStats] = useState({
    pendingIzin: 0,
    pendingCuti: 0,
    pendingSppd: 0,
    totalLibur: 0,
  });

  const [recentIzin, setRecentIzin] = useState([]);
  const [recentCuti, setRecentCuti] = useState([]);

  const isPendingStatus = (statusStr) => {
    const st = (statusStr || '').toLowerCase();
    return st.includes('menunggu') || st.includes('terima atasan') || st.includes('pending') || st === '';
  };

  const fetchDashboardData = async () => {
    try {
      const [izinRes, cutiRes, sppdRes, holidayRes] = await Promise.allSettled([
        apiClient.get('/api/izin'),
        apiClient.get('/api/leave'),
        apiClient.get('/api/sppd/history'),
        apiClient.get('/api/holiday'),
      ]);

      const izinList = izinRes.status === 'fulfilled' ? (Array.isArray(izinRes.value) ? izinRes.value : (izinRes.value?.data || [])) : [];
      const cutiList = cutiRes.status === 'fulfilled' ? (Array.isArray(cutiRes.value) ? cutiRes.value : (cutiRes.value?.data || [])) : [];
      const sppdList = sppdRes.status === 'fulfilled' ? (Array.isArray(sppdRes.value) ? sppdRes.value : (sppdRes.value?.data || [])) : [];
      const holidayList = holidayRes.status === 'fulfilled' ? (Array.isArray(holidayRes.value) ? holidayRes.value : (holidayRes.value?.data || [])) : [];

      const pendingIzinFiltered = izinList.filter((item) => isPendingStatus(item.status));
      const pendingCutiFiltered = cutiList.filter((item) => isPendingStatus(item.status));
      const pendingSppdFiltered = sppdList.filter((item) => isPendingStatus(item.status));

      setStats({
        pendingIzin: pendingIzinFiltered.length,
        pendingCuti: pendingCutiFiltered.length,
        pendingSppd: pendingSppdFiltered.length,
        totalLibur: holidayList.length,
      });

      // ONLY display "menunggu verifikasi" in recent submissions
      setRecentIzin(pendingIzinFiltered.slice(0, 5));
      setRecentCuti(pendingCutiFiltered.slice(0, 5));
    } catch (e) {
      console.error('Error fetching dashboard data:', e);
    } finally {
      setLoading(false);
    }
  };

  // WebSocket Live Real-time Connection for SDM
  useEffect(() => {
    fetchDashboardData();

    const connectWebSocket = () => {
      try {
        const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsHost = window.location.hostname || '127.0.0.1';
        const wsUrl = `${wsProtocol}//${wsHost}:3000/ws/sdm`;
        const ws = new WebSocket(wsUrl);

        ws.onopen = () => {
          setIsWsConnected(true);
        };

        ws.onmessage = (event) => {
          try {
            const msg = JSON.parse(event.data);
            if (msg.event === 'izin_updated' || msg.event === 'cuti_updated' || msg.event === 'sppd_updated') {
              fetchDashboardData();
            }
          } catch (err) {
            fetchDashboardData();
          }
        };

        ws.onclose = () => {
          setIsWsConnected(false);
          setTimeout(connectWebSocket, 5000);
        };

        ws.onerror = () => {
          setIsWsConnected(false);
        };

        wsRef.current = ws;
      } catch (err) {
        console.warn('WebSocket connection error:', err);
      }
    };

    connectWebSocket();

    const pollInterval = setInterval(() => {
      fetchDashboardData();
    }, 15000);

    return () => {
      clearInterval(pollInterval);
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const totalPending = stats.pendingIzin + stats.pendingCuti + stats.pendingSppd;

  return (
    <div className="page-wrapper animate-fade-in">
      {/* SDM Welcome Banner */}
      <div
        style={{
          background: 'linear-gradient(135deg, #4c1d95 0%, #7e22ce 50%, #9333ea 100%)',
          borderRadius: '20px',
          padding: '28px 32px',
          color: 'white',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 12px 28px -8px rgba(107, 33, 168, 0.45)',
          marginBottom: '28px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '20px',
        }}
      >
        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                backgroundColor: 'rgba(255, 255, 255, 0.15)',
                backdropFilter: 'blur(8px)',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontSize: '0.775rem',
                fontWeight: 600,
              }}
            >
              <Sparkles size={14} color="#fef08a" />
              <span>Administrator SDM Aktif</span>
            </div>

            {/* Realtime Live Indicator */}
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                backgroundColor: isWsConnected ? 'rgba(34, 197, 94, 0.25)' : 'rgba(234, 179, 8, 0.25)',
                border: isWsConnected ? '1px solid rgba(34, 197, 94, 0.5)' : '1px solid rgba(234, 179, 8, 0.5)',
                backdropFilter: 'blur(8px)',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontSize: '0.75rem',
                fontWeight: 600,
              }}
            >
              <span
                style={{
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  backgroundColor: isWsConnected ? '#4ade80' : '#facc15',
                  boxShadow: isWsConnected ? '0 0 8px #4ade80' : 'none',
                }}
              />
              <span>{isWsConnected ? 'WebSocket Live Realtime' : 'Menghubungkan Realtime...'}</span>
            </div>
          </div>

          <h2 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em', color: 'white' }}>
            Selamat Datang, {user?.name || 'Admin SDM'}!
          </h2>
          <p style={{ color: '#e9d5ff', fontSize: '0.9rem', marginTop: '4px', maxWidth: '600px' }}>
            {totalPending > 0
              ? `Terdapat ${totalPending} pengajuan kepegawaian baru yang memerlukan verifikasi & persetujuan Anda.`
              : 'Semua berkas pengajuan Izin, Cuti, dan SPPD telah selesai diverifikasi.'}
          </p>
        </div>

        <button
          onClick={() => {
            setLoading(true);
            fetchDashboardData();
          }}
          disabled={loading}
          style={{
            backgroundColor: 'rgba(255, 255, 255, 0.2)',
            backdropFilter: 'blur(8px)',
            border: '1px solid rgba(255, 255, 255, 0.3)',
            color: 'white',
            borderRadius: '12px',
            padding: '10px 18px',
            fontWeight: 600,
            fontSize: '0.85rem',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            cursor: 'pointer',
            transition: 'background 0.2s',
          }}
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          <span>Segarkan Data</span>
        </button>
      </div>

      {/* 4 Summary Action Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
          gap: '20px',
          marginBottom: '32px',
        }}
      >
        {/* Card 1: Verifikasi Izin */}
        <div
          className="glass-card"
          style={{ padding: '24px', cursor: 'pointer', borderTop: '4px solid #3b82f6' }}
          onClick={() => onNavigate('izin')}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)' }}>
                Izin Perlu Verifikasi
              </span>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '4px' }}>
                {loading ? '...' : stats.pendingIzin}
              </div>
            </div>
            <div
              style={{
                width: '44px',
                height: '44px',
                borderRadius: '12px',
                backgroundColor: '#eff6ff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <FileCheck size={22} color="#3b82f6" />
            </div>
          </div>
          <div
            style={{
              marginTop: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '0.825rem',
              fontWeight: 600,
              color: '#3b82f6',
            }}
          >
            <span>Buka Verifikasi Izin</span>
            <ArrowRight size={14} />
          </div>
        </div>

        {/* Card 2: Verifikasi Cuti */}
        <div
          className="glass-card"
          style={{ padding: '24px', cursor: 'pointer', borderTop: '4px solid #10b981' }}
          onClick={() => onNavigate('cuti')}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)' }}>
                Cuti Perlu Verifikasi
              </span>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '4px' }}>
                {loading ? '...' : stats.pendingCuti}
              </div>
            </div>
            <div
              style={{
                width: '44px',
                height: '44px',
                borderRadius: '12px',
                backgroundColor: '#ecfdf5',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <CalendarClock size={22} color="#10b981" />
            </div>
          </div>
          <div
            style={{
              marginTop: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '0.825rem',
              fontWeight: 600,
              color: '#10b981',
            }}
          >
            <span>Buka Verifikasi Cuti</span>
            <ArrowRight size={14} />
          </div>
        </div>

        {/* Card 3: Verifikasi SPPD */}
        <div
          className="glass-card"
          style={{ padding: '24px', cursor: 'pointer', borderTop: '4px solid #f59e0b' }}
          onClick={() => onNavigate('sppd')}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)' }}>
                SPPD Perlu Verifikasi
              </span>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '4px' }}>
                {loading ? '...' : stats.pendingSppd}
              </div>
            </div>
            <div
              style={{
                width: '44px',
                height: '44px',
                borderRadius: '12px',
                backgroundColor: '#fffbeb',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <PlaneTakeoff size={22} color="#f59e0b" />
            </div>
          </div>
          <div
            style={{
              marginTop: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '0.825rem',
              fontWeight: 600,
              color: '#f59e0b',
            }}
          >
            <span>Buka Verifikasi SPPD</span>
            <ArrowRight size={14} />
          </div>
        </div>

        {/* Card 4: Master Libur */}
        <div
          className="glass-card"
          style={{ padding: '24px', cursor: 'pointer', borderTop: '4px solid #8b5cf6' }}
          onClick={() => onNavigate('libur')}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.825rem', fontWeight: 600, color: 'var(--text-muted)' }}>
                Master Hari Libur
              </span>
              <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '4px' }}>
                {loading ? '...' : stats.totalLibur}
              </div>
            </div>
            <div
              style={{
                width: '44px',
                height: '44px',
                borderRadius: '12px',
                backgroundColor: '#f5f3ff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <CalendarDays size={22} color="#8b5cf6" />
            </div>
          </div>
          <div
            style={{
              marginTop: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '0.825rem',
              fontWeight: 600,
              color: '#8b5cf6',
            }}
          >
            <span>Kelola Master Libur</span>
            <ArrowRight size={14} />
          </div>
        </div>
      </div>

      {/* Realtime Submissions Overview */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))', gap: '24px' }}>
        {/* Pengajuan Izin Terbaru (Hanya Menunggu Verifikasi) */}
        <div className="glass-card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800 }}>Pengajuan Izin Terbaru</h3>
              <span style={{ fontSize: '0.72rem', background: '#fffbeb', color: '#b45309', padding: '2px 8px', borderRadius: '6px', fontWeight: 700 }}>
                Menunggu Verifikasi
              </span>
            </div>
            <button
              onClick={() => onNavigate('izin')}
              style={{
                background: 'none',
                border: 'none',
                color: 'var(--color-primary)',
                fontWeight: 600,
                fontSize: '0.825rem',
                cursor: 'pointer',
              }}
            >
              Lihat Semua →
            </button>
          </div>

          {recentIzin.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Tidak ada pengajuan izin yang sedang menunggu verifikasi.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {recentIzin.map((item, idx) => {
                const orgInfo = [item.fakultas, item.prodi, item.unit].filter(Boolean).join(' • ');
                const tglIndo = formatTanggalIndo(item.tanggal_pengajuan || item.tanggal);
                return (
                  <div
                    key={item.id || idx}
                    style={{
                      padding: '14px 16px',
                      borderRadius: '12px',
                      border: '1px solid var(--border-light)',
                      backgroundColor: '#ffffff',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      gap: '12px',
                      boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
                    }}
                  >
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                        <span style={{ fontWeight: 800, fontSize: '0.925rem', color: 'var(--text-main)' }}>
                          {item.nama_pemohon || item.nama || item.nip}
                        </span>
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', background: '#f1f5f9', padding: '2px 6px', borderRadius: '4px' }}>
                          NIP: {item.nip}
                        </span>
                      </div>

                      {orgInfo && (
                        <div style={{ fontSize: '0.75rem', fontWeight: 600, color: '#64748b', marginTop: '2px' }}>
                          {orgInfo}
                        </div>
                      )}

                      <div style={{ fontSize: '0.775rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                        📅 {tglIndo} • <span style={{ color: '#334155' }}>{item.tujuan || item.keterangan || 'Izin'}</span>
                      </div>
                    </div>
                    <Badge status={item.status} />
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Pengajuan Cuti Terbaru (Hanya Menunggu Verifikasi) */}
        <div className="glass-card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800 }}>Pengajuan Cuti Terbaru</h3>
              <span style={{ fontSize: '0.72rem', background: '#fffbeb', color: '#b45309', padding: '2px 8px', borderRadius: '6px', fontWeight: 700 }}>
                Menunggu Verifikasi
              </span>
            </div>
            <button
              onClick={() => onNavigate('cuti')}
              style={{
                background: 'none',
                border: 'none',
                color: 'var(--color-primary)',
                fontWeight: 600,
                fontSize: '0.825rem',
                cursor: 'pointer',
              }}
            >
              Lihat Semua →
            </button>
          </div>

          {recentCuti.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Tidak ada pengajuan cuti yang sedang menunggu verifikasi.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {recentCuti.map((item, idx) => {
                const orgInfo = [item.fakultas, item.prodi, item.unit].filter(Boolean).join(' • ');
                const rentangIndo = formatRentangTanggalIndo(item.tanggal_mulai, item.tanggal_selesai);
                return (
                  <div
                    key={item.id || idx}
                    style={{
                      padding: '14px 16px',
                      borderRadius: '12px',
                      border: '1px solid var(--border-light)',
                      backgroundColor: '#ffffff',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      gap: '12px',
                      boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
                    }}
                  >
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                        <span style={{ fontWeight: 800, fontSize: '0.925rem', color: 'var(--text-main)' }}>
                          {item.nama_pemohon || item.nama || item.nip}
                        </span>
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', background: '#f1f5f9', padding: '2px 6px', borderRadius: '4px' }}>
                          NIP: {item.nip}
                        </span>
                      </div>

                      {orgInfo && (
                        <div style={{ fontSize: '0.75rem', fontWeight: 600, color: '#64748b', marginTop: '2px' }}>
                          {orgInfo}
                        </div>
                      )}

                      <div style={{ fontSize: '0.775rem', color: 'var(--text-muted)', marginTop: '4px' }}>
                        🏖️ {rentangIndo} ({item.jumlah_hari || 1} Hari) • <span style={{ color: '#334155' }}>{item.alasan || 'Cuti'}</span>
                      </div>
                    </div>
                    <Badge status={item.status} />
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
