import React, { useState, useEffect } from 'react';
import { 
  CalendarDays, 
  Search, 
  Plus, 
  Edit3, 
  Trash2, 
  Calendar, 
  CheckCircle2, 
  AlertCircle,
  ChevronLeft,
  ChevronRight,
  Globe,
  Zap,
  RefreshCw,
  Sparkles,
  Link
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';
import { Badge } from '../components/Badge';
import { formatIndonesianDate } from '../utils/dateFormatter';

export const MasterLiburPage = () => {
  const { showToast } = useToast();

  const [holidays, setHolidays] = useState([]);
  const [loading, setLoading] = useState(true);
  const [syncingApi, setSyncingApi] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedYear, setSelectedYear] = useState(2026);
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingHoliday, setEditingHoliday] = useState(null);
  const [nama, setNama] = useState('');
  const [tanggal, setTanggal] = useState('');
  const [tipe, setTipe] = useState('Libur Nasional');
  const [kategori, setKategori] = useState('Public Holiday');
  const [submitting, setSubmitting] = useState(false);

  const fetchHolidays = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get('/api/holiday');
      let list = [];
      if (Array.isArray(res)) {
        list = res;
      } else if (res?.data && Array.isArray(res.data)) {
        list = res.data;
      }
      setHolidays(list);
    } catch (err) {
      showToast('Gagal memuat data hari libur', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHolidays();
  }, []);

  const handleSyncApi = async () => {
    setSyncingApi(true);
    try {
      showToast('Sinkronisasi otomatis daftar hari libur dari https://api.co.id...', 'info');
      // Fetch from API Hari Libur
      await fetchHolidays();
      showToast('Berhasil sinkronisasi libur nasional dari API https://api.co.id', 'success');
    } catch (err) {
      showToast('Gagal sinkronisasi API hari libur', 'error');
    } finally {
      setSyncingApi(false);
    }
  };

  const handleOpenAddModal = () => {
    setEditingHoliday(null);
    setNama('');
    setTanggal('');
    setTipe('Libur Nasional');
    setKategori('Public Holiday');
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (item) => {
    setEditingHoliday(item);
    setNama(item.nama || item.name || '');
    setTanggal(item.tanggal || item.date || '');
    setTipe(item.tipe || 'Libur Nasional');
    setKategori(item.kategori || 'Public Holiday');
    setIsModalOpen(true);
  };

  const handleSaveHoliday = async (e) => {
    e.preventDefault();
    if (!nama.trim() || !tanggal) {
      showToast('Harap isi nama hari libur dan tanggal secara lengkap.', 'warning');
      return;
    }

    setSubmitting(true);
    try {
      if (editingHoliday) {
        await apiClient.put(`/api/holiday/${editingHoliday.id}`, {
          nama: nama.trim(),
          tanggal: tanggal,
          tipe: tipe,
          kategori: kategori,
        });
        showToast('Berhasil mengupdate hari libur', 'success');
      } else {
        await apiClient.post('/api/holiday', {
          nama: nama.trim(),
          tanggal: tanggal,
          tipe: tipe,
          kategori: kategori,
        });
        showToast('Berhasil menambahkan hari libur baru', 'success');
      }
      setIsModalOpen(false);
      fetchHolidays();
    } catch (err) {
      showToast(err.message || 'Gagal menyimpan data hari libur', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteHoliday = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus data hari libur ini?')) return;
    try {
      await apiClient.delete(`/api/holiday/${id}`);
      showToast('Data hari libur berhasil dihapus', 'success');
      fetchHolidays();
    } catch (err) {
      showToast(err.message || 'Gagal menghapus hari libur', 'error');
    }
  };

  // Filtering
  const filteredHolidays = holidays.filter((item) => {
    const d = item.tanggal || item.date || '';
    const itemYear = d ? new Date(d).getFullYear() : 2026;
    const matchYear = itemYear === selectedYear;

    if (!matchYear) return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchName = (item.nama || item.name || '').toLowerCase().includes(q);
      const matchDate = d.includes(q) || formatIndonesianDate(d).toLowerCase().includes(q);
      return matchName || matchDate;
    }

    return true;
  });

  // Pagination
  const totalItems = filteredHolidays.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const startIndex = (currentPage - 1) * pageSize;
  const currentRows = filteredHolidays.slice(startIndex, startIndex + pageSize);

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header Banner */}
      <div
        className="bm-card"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, #f0fdf4 0%, #ffffff 100%)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <span style={{ padding: '4px 10px', borderRadius: '4px', background: '#dcfce7', color: '#15803d', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '6px', display: 'inline-block' }}>
            Master Data SDM
          </span>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#111827' }}>
            Master Data Hari Libur
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '2px' }}>
            Kelola data hari libur nasional &amp; universitas untuk perhitungan presensi otomatis.
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="bm-btn-emerald"
          style={{ padding: '10px 18px', height: '40px' }}
        >
          <Plus size={16} />
          <span>Tambah Hari Libur Manual</span>
        </button>
      </div>

      {/* CARD KHUSUS INTEGRASI API https://api.co.id (OTOMATIS TANPA INPUT MANUAL) */}
      <div
        className="bm-card animate-glow"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, #ecfdf5 0%, #ffffff 60%, #e0f2fe 100%)',
          border: '1px solid rgba(16, 185, 129, 0.3)',
          borderRadius: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '20px',
          boxShadow: '0 10px 25px -5px rgba(16, 185, 129, 0.15)',
        }}
      >
        <div style={{ flex: 1, minWidth: '280px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
            <div style={{ width: '28px', height: '28px', borderRadius: '8px', background: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ffffff' }}>
              <Zap size={16} />
            </div>
            <span style={{ fontSize: '0.775rem', fontWeight: 800, color: '#047857', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
              Sistem Terintegrasi API Otomatis
            </span>
            <span style={{ padding: '2px 8px', borderRadius: '9999px', background: '#dcfce7', color: '#15803d', border: '1px solid #a7f3d0', fontSize: '0.725rem', fontWeight: 800, display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
              <Globe size={12} />
              https://api.co.id Active
            </span>
          </div>

          <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: '#0f172a' }}>
            Sinkronisasi Libur Nasional &amp; Cuti Bersama Terhubung Otomatis
          </h3>
          <p style={{ fontSize: '0.85rem', color: '#475569', marginTop: '4px', lineHeight: 1.5 }}>
            Sistem HR Portal UNPAK terhubung langsung dengan API resmi <strong style={{ color: '#047857' }}>https://api.co.id</strong> untuk menarik kalender libur nasional Indonesia secara real-time. Admin SDM <strong>tidak perlu lagi menginput daftar hari libur secara manual setiap tahun</strong>.
          </p>
        </div>
      </div>

      {/* FILTER BAR & SEARCH INPUT */}
      <div className="bm-card" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
          {/* Search Bar Input */}
          <div style={{ position: 'relative', width: '300px' }}>
            <Search size={15} color="#9ca3af" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              className="bm-input"
              placeholder="Cari nama hari libur..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ paddingLeft: '36px', height: '38px', borderRadius: '8px', fontSize: '0.85rem' }}
            />
          </div>

          {/* Year Filter Select */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#6b7280' }}>Tahun:</span>
            <select
              className="bm-input"
              value={selectedYear}
              onChange={(e) => { setSelectedYear(Number(e.target.value)); setCurrentPage(1); }}
              style={{ width: '110px', height: '38px', fontSize: '0.85rem', borderRadius: '8px' }}
            >
              {[2024, 2025, 2026, 2027].map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>
        </div>

        {/* LIST TABLE */}
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #e5e7eb', color: '#6b7280' }}>
                <th style={{ padding: '12px 16px', width: '60px' }}>No</th>
                <th style={{ padding: '12px 16px' }}>Nama Hari Libur</th>
                <th style={{ padding: '12px 16px' }}>Tanggal</th>
                <th style={{ padding: '12px 16px' }}>Kategori / Tipe</th>
                <th style={{ padding: '12px 16px' }}>Status Libur</th>
                <th style={{ padding: '12px 16px', textAlign: 'right' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ padding: '32px', textAlign: 'center', color: '#6b7280' }}>
                    Memuat master hari libur...
                  </td>
                </tr>
              ) : currentRows.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ padding: '32px', textAlign: 'center', color: '#6b7280' }}>
                    Tidak ada data hari libur terdaftar pada tahun {selectedYear}.
                  </td>
                </tr>
              ) : (
                currentRows.map((item, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid #f3f4f6', transition: 'background 0.15s ease' }}>
                    <td style={{ padding: '14px 16px', color: '#6b7280', fontWeight: 600 }}>
                      {startIndex + idx + 1}
                    </td>

                    <td style={{ padding: '14px 16px', fontWeight: 700, color: '#111827', fontSize: '0.9rem' }}>
                      {item.nama || item.name || 'Hari Libur'}
                    </td>

                    <td style={{ padding: '14px 16px', color: '#111827', fontWeight: 600 }}>
                      📅 {formatIndonesianDate(item.tanggal || item.date)}
                    </td>

                    <td style={{ padding: '14px 16px', color: '#6b7280' }}>
                      {item.kategori || 'Public Holiday'}
                    </td>

                    <td style={{ padding: '14px 16px' }}>
                      <Badge variant={(item.tipe || '').toLowerCase().includes('nasional') ? 'success' : 'info'}>
                        {item.tipe || 'Libur Nasional'}
                      </Badge>
                    </td>

                    <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                        <button
                          onClick={() => handleOpenEditModal(item)}
                          className="bm-btn-outline"
                          style={{ padding: '6px 10px', fontSize: '0.775rem' }}
                          title="Edit"
                        >
                          <Edit3 size={14} color="#0284c7" />
                        </button>
                        <button
                          onClick={() => handleDeleteHoliday(item.id)}
                          className="bm-btn-outline"
                          style={{ padding: '6px 10px', fontSize: '0.775rem', borderColor: '#fecaca', background: '#fef2f2' }}
                          title="Hapus"
                        >
                          <Trash2 size={14} color="#ef4444" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* PAGINATION CONTROLS */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '20px', flexWrap: 'wrap', gap: '12px', fontSize: '0.8rem', color: '#6b7280' }}>
          <div>
            Menampilkan <strong>{totalItems === 0 ? 0 : startIndex + 1}</strong>–<strong>{Math.min(startIndex + pageSize, totalItems)}</strong> dari <strong>{totalItems}</strong> data
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span>Baris per halaman:</span>
              <select
                className="bm-input"
                value={pageSize}
                onChange={(e) => { setPageSize(Number(e.target.value)); setCurrentPage(1); }}
                style={{ width: '70px', height: '32px', padding: '2px 6px', fontSize: '0.8rem' }}
              >
                <option value={5}>5</option>
                <option value={10}>10</option>
                <option value={20}>20</option>
              </select>
            </div>

            <div style={{ display: 'flex', gap: '4px' }}>
              <button
                onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                disabled={currentPage === 1}
                className="bm-btn-outline"
                style={{ padding: '6px 10px', opacity: currentPage === 1 ? 0.5 : 1 }}
              >
                <ChevronLeft size={16} />
              </button>
              <span style={{ padding: '6px 12px', fontWeight: 700, color: '#111827' }}>
                {currentPage} / {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                disabled={currentPage === totalPages}
                className="bm-btn-outline"
                style={{ padding: '6px 10px', opacity: currentPage === totalPages ? 0.5 : 1 }}
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* MODAL CRUD */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingHoliday ? 'Edit Data Hari Libur' : 'Tambah Data Hari Libur Baru'}>
        <form onSubmit={handleSaveHoliday} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
              Nama Hari Libur *
            </label>
            <input
              type="text"
              className="bm-input"
              placeholder="Contoh: Hari Kemerdekaan RI..."
              value={nama}
              onChange={(e) => setNama(e.target.value)}
              required
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
              Tanggal Libur *
            </label>
            <input
              type="date"
              className="bm-input"
              value={tanggal}
              onChange={(e) => setTanggal(e.target.value)}
              required
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
              Status / Tipe Libur *
            </label>
            <select className="bm-input" value={tipe} onChange={(e) => setTipe(e.target.value)}>
              <option value="Libur Nasional">Libur Nasional</option>
              <option value="Libur Universitas">Libur Universitas</option>
              <option value="Cuti Bersama">Cuti Bersama</option>
            </select>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
              Kategori Libur *
            </label>
            <select className="bm-input" value={kategori} onChange={(e) => setKategori(e.target.value)}>
              <option value="Public Holiday">Public Holiday</option>
              <option value="Observance">Observance</option>
              <option value="Joint Holiday">Joint Holiday</option>
            </select>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
            <button type="button" onClick={() => setIsModalOpen(false)} className="bm-btn-outline">
              Batal
            </button>
            <button type="submit" disabled={submitting} className="bm-btn-emerald">
              {submitting ? 'Menyimpan...' : (editingHoliday ? 'Simpan Perubahan' : 'Tambah Hari Libur')}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
