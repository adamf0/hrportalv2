import React, { useState, useEffect } from 'react';
import { 
  Clock, 
  MapPin, 
  CheckCircle2, 
  AlertCircle, 
  LogIn, 
  LogOut, 
  Calendar, 
  Sparkles,
  Search,
  Filter,
  FileText,
  UserCheck
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';

export const PresensiPage = () => {
  const { user } = useAuth();
  const { showToast } = useToast();

  const [currentTime, setCurrentTime] = useState(new Date());
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  const [todayCheckIn, setTodayCheckIn] = useState(null);
  const [todayCheckOut, setTodayCheckOut] = useState(null);

  // Modal for Reason
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalType, setModalType] = useState('late'); // 'late' or 'early'
  const [reasonText, setReasonText] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const fetchAttendanceHistory = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get('/api/attendance/history');
      let items = [];
      if (Array.isArray(res)) {
        items = res;
      } else if (res?.data && Array.isArray(res.data)) {
        items = res.data;
      }

      setHistory(items);

      const todayStr = new Date().toISOString().split('T')[0];
      const todayRecord = items.find((item) => (item.tanggal || '').includes(todayStr));

      if (todayRecord) {
        setTodayCheckIn(todayRecord.absen_masuk || todayRecord.check_in || null);
        setTodayCheckOut(todayRecord.absen_keluar || todayRecord.check_out || null);
      }
    } catch (err) {
      console.warn('Gagal memuat riwayat presensi:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAttendanceHistory();
  }, []);

  const hours = currentTime.getHours();
  const minutes = currentTime.getMinutes();
  const isLate = hours > 8 || (hours === 8 && minutes > 3);

  const handleCheckInClick = () => {
    if (todayCheckIn) {
      showToast('Anda sudah melakukan Absen Masuk hari ini.', 'info');
      return;
    }

    if (isLate) {
      setModalType('late');
      setReasonText('');
      setIsModalOpen(true);
    } else {
      executeCheckIn('');
    }
  };

  const handleCheckOutClick = () => {
    if (!todayCheckIn) {
      showToast('Anda belum melakukan Absen Masuk hari ini.', 'warning');
      return;
    }
    if (todayCheckOut) {
      showToast('Anda sudah melakukan Absen Keluar hari ini.', 'info');
      return;
    }

    const checkInTime = new Date(todayCheckIn);
    const now = new Date();
    const diffMinutes = Math.floor((now - checkInTime) / (1000 * 60));

    if (diffMinutes < 30) {
      setModalType('early');
      setReasonText('');
      setIsModalOpen(true);
    } else {
      executeCheckOut('');
    }
  };

  const executeCheckIn = async (reason) => {
    setSubmitting(true);
    try {
      await apiClient.post('/api/attendance/check-in', {
        nip: user?.nip || user?.username || '',
        nidn: user?.nidn || '',
        nama: user?.name || '',
        unit: user?.unit || '',
        fakultas: user?.fakultas || '',
        prodi: user?.prodi || '',
        latitude: -6.5976,
        longitude: 106.8066,
        note: reason || (isLate ? 'Telat Masuk' : 'Tepat Waktu'),
      });

      showToast('Absen Masuk Berhasil!', 'success');
      setIsModalOpen(false);
      fetchAttendanceHistory();
    } catch (err) {
      showToast(err.message || 'Gagal melakukan Absen Masuk', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const executeCheckOut = async (reason) => {
    setSubmitting(true);
    try {
      await apiClient.post('/api/attendance/check-out', {
        nip: user?.nip || user?.username || '',
        nidn: user?.nidn || '',
        note: reason || 'Absen Keluar',
      });

      showToast('Absen Keluar Berhasil!', 'success');
      setIsModalOpen(false);
      fetchAttendanceHistory();
    } catch (err) {
      showToast(err.message || 'Gagal melakukan Absen Keluar', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleModalSubmit = (e) => {
    e.preventDefault();
    if (!reasonText.trim()) {
      showToast('Harap masukkan alasan terlebih dahulu.', 'warning');
      return;
    }
    if (modalType === 'late') {
      executeCheckIn(reasonText.trim());
    } else {
      executeCheckOut(reasonText.trim());
    }
  };

  const filteredHistory = history.filter((item) => {
    const q = searchQuery.toLowerCase();
    return (
      (item.tanggal || '').toLowerCase().includes(q) ||
      (item.note || item.catatan || '').toLowerCase().includes(q) ||
      (item.status || '').toLowerCase().includes(q)
    );
  });

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header Banner */}
      <div
        className="glass-card"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, #f3e8ff 0%, #e0f2fe 100%)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
            <span
              style={{
                padding: '4px 10px',
                borderRadius: '20px',
                background: '#e9d5ff',
                color: '#7c3aed',
                fontSize: '0.75rem',
                fontWeight: 700,
                textTransform: 'uppercase',
              }}
            >
              Presensi Mandiri
            </span>
            <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
              Universitas Pakuan
            </span>
          </div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0f172a' }}>
            Panel Presensi Real-Time
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#64748b', marginTop: '2px' }}>
            {user?.name} • NIP: {user?.nip || user?.username} ({user?.role?.toUpperCase() || 'DOSEN/TENDIK'})
          </p>
        </div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            background: '#ffffff',
            padding: '12px 20px',
            borderRadius: '16px',
            border: '1px solid #e2e8f0',
            boxShadow: 'var(--shadow-sm)',
          }}
        >
          <Clock size={24} color="#0284c7" />
          <div>
            <div style={{ fontSize: '1.4rem', fontWeight: 800, fontFamily: 'monospace', color: '#0284c7' }}>
              {currentTime.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })} WIB
            </div>
            <div style={{ fontSize: '0.75rem', color: '#64748b' }}>
              {currentTime.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
            </div>
          </div>
        </div>
      </div>

      {/* Interactive Action Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
        {/* Card Absen Masuk */}
        <div
          className="glass-card"
          style={{
            padding: '24px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            borderLeft: todayCheckIn ? '4px solid #10b981' : (isLate ? '4px solid #f59e0b' : '4px solid #7c3aed'),
          }}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    background: todayCheckIn ? '#ecfdf5' : '#faf5ff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <LogIn size={22} color={todayCheckIn ? '#10b981' : '#7c3aed'} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Absen Masuk</h3>
                  <p style={{ fontSize: '0.775rem', color: '#64748b' }}>Batas waktu 08:03 WIB</p>
                </div>
              </div>

              {todayCheckIn ? (
                <Badge variant="success">Sudah Masuk</Badge>
              ) : isLate ? (
                <Badge variant="warning">Terlambat (&gt;08:03)</Badge>
              ) : (
                <Badge variant="info">Tepat Waktu</Badge>
              )}
            </div>

            <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', marginBottom: '20px', border: '1px solid #e2e8f0' }}>
              <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Waktu Absen Masuk:</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: todayCheckIn ? '#10b981' : '#0f172a', marginTop: '2px' }}>
                {todayCheckIn ? new Date(todayCheckIn).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB' : '-- : --'}
              </div>
            </div>
          </div>

          <button
            onClick={handleCheckInClick}
            disabled={!!todayCheckIn || submitting}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: '12px',
              border: 'none',
              background: todayCheckIn
                ? '#e2e8f0'
                : 'linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%)',
              color: todayCheckIn ? '#94a3b8' : '#ffffff',
              fontWeight: 800,
              cursor: todayCheckIn || submitting ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              boxShadow: todayCheckIn ? 'none' : '0 4px 14px rgba(124, 58, 237, 0.3)',
              transition: 'all 0.2s ease',
            }}
          >
            <LogIn size={18} />
            <span>{todayCheckIn ? 'Absen Masuk Selesai' : (isLate ? 'Absen Masuk (Isi Alasan)' : 'Absen Masuk Sekarang')}</span>
          </button>
        </div>

        {/* Card Absen Keluar */}
        <div
          className="glass-card"
          style={{
            padding: '24px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            borderLeft: todayCheckOut ? '4px solid #10b981' : '4px solid #0284c7',
          }}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    background: '#e0f2fe',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <LogOut size={22} color="#0284c7" />
                </div>
                <div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#0f172a' }}>Absen Keluar</h3>
                  <p style={{ fontSize: '0.775rem', color: '#64748b' }}>Pulang Kerja Hari Ini</p>
                </div>
              </div>

              {todayCheckOut ? (
                <Badge variant="success">Sudah Keluar</Badge>
              ) : (
                <Badge variant="info">Belum Absen Keluar</Badge>
              )}
            </div>

            <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', marginBottom: '20px', border: '1px solid #e2e8f0' }}>
              <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Waktu Absen Keluar:</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800, color: todayCheckOut ? '#10b981' : '#0f172a', marginTop: '2px' }}>
                {todayCheckOut ? new Date(todayCheckOut).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB' : '-- : --'}
              </div>
            </div>
          </div>

          <button
            onClick={handleCheckOutClick}
            disabled={!todayCheckIn || !!todayCheckOut || submitting}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: '12px',
              border: 'none',
              background: (!todayCheckIn || todayCheckOut)
                ? '#e2e8f0'
                : 'linear-gradient(135deg, #0284c7 0%, #0369a1 100%)',
              color: (!todayCheckIn || todayCheckOut) ? '#94a3b8' : '#ffffff',
              fontWeight: 800,
              cursor: (!todayCheckIn || todayCheckOut || submitting) ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              boxShadow: (!todayCheckIn || todayCheckOut) ? 'none' : '0 4px 14px rgba(2, 132, 199, 0.3)',
              transition: 'all 0.2s ease',
            }}
          >
            <LogOut size={18} />
            <span>{todayCheckOut ? 'Absen Keluar Selesai' : 'Absen Keluar Sekarang'}</span>
          </button>
        </div>
      </div>

      {/* Attendance History Section */}
      <div className="glass-card" style={{ padding: '24px' }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '16px',
            marginBottom: '20px',
          }}
        >
          <div>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#0f172a' }}>
              Riwayat Presensi Bulan Ini
            </h2>
            <p style={{ fontSize: '0.8rem', color: '#64748b' }}>
              Catatan kehadiran, jam masuk/keluar, dan alasan keterlambatan/pulang cepat.
            </p>
          </div>

          <div style={{ position: 'relative', minWidth: '260px' }}>
            <Search size={18} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              className="form-input"
              placeholder="Cari tanggal atau alasan..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ paddingLeft: '38px', borderRadius: '10px' }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>
            Memuat riwayat presensi...
          </div>
        ) : filteredHistory.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#64748b', background: '#f8fafc', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
            Belum ada catatan riwayat presensi.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.875rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e2e8f0', color: '#64748b' }}>
                  <th style={{ padding: '12px 16px' }}>Tanggal</th>
                  <th style={{ padding: '12px 16px' }}>Absen Masuk</th>
                  <th style={{ padding: '12px 16px' }}>Absen Keluar</th>
                  <th style={{ padding: '12px 16px' }}>Catatan / Alasan</th>
                  <th style={{ padding: '12px 16px' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {filteredHistory.map((row, idx) => (
                  <tr
                    key={idx}
                    style={{
                      borderBottom: '1px solid #f1f5f9',
                      transition: 'background 0.15s ease',
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.background = '#f8fafc'}
                    onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                  >
                    <td style={{ padding: '14px 16px', fontWeight: 600, color: '#0f172a' }}>
                      {row.tanggal || row.date || '-'}
                    </td>
                    <td style={{ padding: '14px 16px', color: '#0284c7', fontWeight: 600 }}>
                      {row.absen_masuk || row.check_in || '-'}
                    </td>
                    <td style={{ padding: '14px 16px', color: '#7c3aed', fontWeight: 600 }}>
                      {row.absen_keluar || row.check_out || '-'}
                    </td>
                    <td style={{ padding: '14px 16px', color: '#475569', maxWidth: '300px' }}>
                      {row.note || row.catatan || row.alasan || '-'}
                    </td>
                    <td style={{ padding: '14px 16px' }}>
                      {(row.note || '').toLowerCase().includes('telat') ? (
                        <Badge variant="warning">Terlambat</Badge>
                      ) : (row.note || '').toLowerCase().includes('pulang cepat') ? (
                        <Badge variant="danger">Pulang Cepat</Badge>
                      ) : (
                        <Badge variant="success">Hadir</Badge>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal for Late / Early Reason */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => !submitting && setIsModalOpen(false)}
        title={modalType === 'late' ? 'Alasan Telat Masuk' : 'Alasan Pulang Cepat'}
      >
        <form onSubmit={handleModalSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div
            style={{
              padding: '12px 14px',
              borderRadius: '12px',
              background: modalType === 'late' ? '#fffbeb' : '#fef2f2',
              border: `1px solid ${modalType === 'late' ? '#fde68a' : '#fecaca'}`,
              color: modalType === 'late' ? '#b45309' : '#b91c1c',
              fontSize: '0.85rem',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
            }}
          >
            <AlertCircle size={20} style={{ flexShrink: 0 }} />
            <div>
              {modalType === 'late'
                ? 'Waktu masuk Anda melebihi 08:03 WIB. Harap berikan alasan keterlambatan Anda.'
                : 'Durasi kerja kurang dari 30 menit. Harap beri alasan mendesak untuk pulang cepat.'}
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 700, color: '#0f172a', marginBottom: '6px' }}>
              {modalType === 'late' ? 'Alasan Telat Masuk *' : 'Alasan Pulang Cepat *'}
            </label>
            <textarea
              className="form-textarea"
              rows={4}
              placeholder={modalType === 'late' ? 'Contoh: Kendala cuaca hujan deras / kemacetan lalulintas...' : 'Contoh: Urusan keluarga mendesak / keperluan medis...'}
              value={reasonText}
              onChange={(e) => setReasonText(e.target.value)}
              required
              disabled={submitting}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '10px' }}>
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              disabled={submitting}
              style={{
                padding: '10px 18px',
                borderRadius: '10px',
                border: '1px solid #e2e8f0',
                background: '#ffffff',
                color: '#64748b',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={submitting}
              style={{
                padding: '10px 20px',
                borderRadius: '10px',
                border: 'none',
                background: modalType === 'late'
                  ? 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'
                  : 'linear-gradient(135deg, #ef4444 0%, #b91c1c 100%)',
                color: '#ffffff',
                fontWeight: 700,
                cursor: submitting ? 'not-allowed' : 'pointer',
              }}
            >
              {submitting ? 'Mengirim...' : 'Kirim Presensi'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
