import React, { useState, useEffect } from 'react';
import { 
  Plus, 
  Search, 
  Calendar, 
  Edit2, 
  Trash2, 
  AlertTriangle
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';
import { Badge } from '../components/Badge';
import { Pagination } from '../components/Pagination';
import { formatTanggalIndo } from '../utils/date';

export const MasterLiburPage = () => {
  const { showToast } = useToast();

  const [holidays, setHolidays] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [searchQuery, setSearchQuery] = useState('');

  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Modal States
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedHoliday, setSelectedHoliday] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    nama: '',
    tanggal: '',
    type: 'Libur Nasional',
    is_national_holiday: true,
  });

  const fetchHolidays = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get('/api/holiday', { year: selectedYear });
      let list = [];
      if (Array.isArray(res)) {
        list = res;
      } else if (res?.data && Array.isArray(res.data)) {
        list = res.data;
      }
      setHolidays(list);
    } catch (err) {
      showToast(err.message || 'Gagal memuat master libur', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHolidays();
    setCurrentPage(1);
  }, [selectedYear]);

  const handleOpenCreate = () => {
    setFormData({
      nama: '',
      tanggal: `${selectedYear}-01-01`,
      type: 'Libur Nasional',
      is_national_holiday: true,
    });
    setIsCreateModalOpen(true);
  };

  const handleOpenEdit = (holiday) => {
    setSelectedHoliday(holiday);
    setFormData({
      nama: holiday.nama || '',
      tanggal: holiday.tanggal ? holiday.tanggal.split('T')[0] : '',
      type: holiday.type || 'Libur Nasional',
      is_national_holiday: !!holiday.is_national_holiday || holiday.libur === 1,
    });
    setIsEditModalOpen(true);
  };

  const handleOpenDelete = (holiday) => {
    setSelectedHoliday(holiday);
    setIsDeleteModalOpen(true);
  };

  const handleCreateSubmit = async (e) => {
    e.preventDefault();
    if (!formData.nama.trim() || !formData.tanggal) {
      showToast('Nama hari libur dan tanggal wajib diisi.', 'error');
      return;
    }

    try {
      await apiClient.post('/api/holiday', {
        nama: formData.nama.trim(),
        tanggal: formData.tanggal,
        type: formData.type,
        is_national_holiday: formData.is_national_holiday,
      });
      showToast('Hari libur berhasil ditambahkan!', 'success');
      setIsCreateModalOpen(false);
      fetchHolidays();
    } catch (err) {
      showToast(err.message || 'Gagal menambahkan hari libur', 'error');
    }
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    if (!selectedHoliday) return;

    try {
      await apiClient.put(`/api/holiday/${selectedHoliday.id}`, {
        nama: formData.nama.trim(),
        tanggal: formData.tanggal,
        type: formData.type,
        is_national_holiday: formData.is_national_holiday,
      });
      showToast('Hari libur berhasil diperbarui!', 'success');
      setIsEditModalOpen(false);
      fetchHolidays();
    } catch (err) {
      showToast(err.message || 'Gagal memperbarui hari libur', 'error');
    }
  };

  const handleDeleteSubmit = async () => {
    if (!selectedHoliday) return;

    try {
      await apiClient.delete(`/api/holiday/${selectedHoliday.id}`);
      showToast('Hari libur berhasil dihapus!', 'success');
      setIsDeleteModalOpen(false);
      fetchHolidays();
    } catch (err) {
      showToast(err.message || 'Gagal menghapus hari libur', 'error');
    }
  };

  const filteredHolidays = holidays.filter((h) =>
    (h.nama || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalItems = filteredHolidays.length;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedHolidays = filteredHolidays.slice(startIndex, startIndex + itemsPerPage);

  const handleSearchChange = (val) => {
    setSearchQuery(val);
    setCurrentPage(1);
  };

  return (
    <div className="page-wrapper animate-fade-in">
      {/* Header & Actions */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
          marginBottom: '24px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Master Data Hari Libur</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Kelola data hari libur nasional & universitas untuk perhitungan presensi
          </p>
        </div>

        <button onClick={handleOpenCreate} className="btn btn-primary">
          <Plus size={18} />
          <span>Tambah Hari Libur</span>
        </button>
      </div>

      {/* Filter Toolbar */}
      <div
        className="glass-card"
        style={{
          padding: '16px 20px',
          marginBottom: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flex: 1, minWidth: '240px' }}>
          <div style={{ position: 'relative', width: '100%', maxWidth: '360px' }}>
            <Search
              size={18}
              color="var(--text-muted)"
              style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }}
            />
            <input
              type="text"
              className="form-input"
              placeholder="Cari nama hari libur..."
              value={searchQuery}
              onChange={(e) => handleSearchChange(e.target.value)}
              style={{ paddingLeft: '38px' }}
            />
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-muted)' }}>Tahun:</span>
          <select
            className="form-select"
            value={selectedYear}
            onChange={(e) => setSelectedYear(parseInt(e.target.value))}
            style={{ width: '120px', padding: '8px 12px' }}
          >
            {[2024, 2025, 2026, 2027].map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Table with Pagination */}
      <div className="table-container">
        <table className="custom-table">
          <thead>
            <tr>
              <th style={{ width: '60px' }}>No</th>
              <th>Nama Hari Libur</th>
              <th>Tanggal</th>
              <th>Kategori / Tipe</th>
              <th>Status Libur</th>
              <th style={{ width: '110px', textAlign: 'center' }}>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '40px' }}>
                  Memuat data master libur...
                </td>
              </tr>
            ) : paginatedHolidays.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                  Tidak ada data hari libur pada tahun {selectedYear}.
                </td>
              </tr>
            ) : (
              paginatedHolidays.map((item, index) => {
                const globalIndex = startIndex + index + 1;
                const tglIndo = formatTanggalIndo(item.tanggal);
                return (
                  <tr key={item.id || index}>
                    <td style={{ fontWeight: 600, color: 'var(--text-muted)' }}>{globalIndex}</td>
                    <td style={{ fontWeight: 700 }}>{item.nama}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <Calendar size={15} color="var(--text-muted)" />
                        <span style={{ fontWeight: 600, color: 'var(--text-main)' }}>{tglIndo}</span>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.825rem', color: 'var(--text-muted)' }}>
                        {item.type || 'Libur Nasional'}
                      </span>
                    </td>
                    <td>
                      <Badge type={item.is_national_holiday || item.libur === 1 ? 'Libur Nasional' : 'Libur Universitas'} />
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                        <button
                          onClick={() => handleOpenEdit(item)}
                          style={{
                            background: '#f1f5f9',
                            border: 'none',
                            padding: '6px',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            color: '#475569',
                          }}
                          title="Ubah Libur"
                        >
                          <Edit2 size={16} />
                        </button>
                        <button
                          onClick={() => handleOpenDelete(item)}
                          style={{
                            background: '#fef2f2',
                            border: 'none',
                            padding: '6px',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            color: '#ef4444',
                          }}
                          title="Hapus Libur"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>

        {/* Paging Footer */}
        {!loading && totalItems > 0 && (
          <Pagination
            currentPage={currentPage}
            totalItems={totalItems}
            itemsPerPage={itemsPerPage}
            onPageChange={(page) => setCurrentPage(page)}
            onItemsPerPageChange={(limit) => {
              setItemsPerPage(limit);
              setCurrentPage(1);
            }}
          />
        )}
      </div>

      {/* Modal: Tambah Hari Libur */}
      <Modal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        title="Tambah Master Hari Libur"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', width: '100%', gap: '12px' }}>
            <button className="btn btn-secondary" onClick={() => setIsCreateModalOpen(false)}>
              Batal
            </button>
            <button className="btn btn-primary" onClick={handleCreateSubmit}>
              Simpan Hari Libur
            </button>
          </div>
        }
      >
        <form onSubmit={handleCreateSubmit}>
          <div className="form-group">
            <label className="form-label">Nama Hari Libur</label>
            <input
              type="text"
              className="form-input"
              placeholder="Contoh: Hari Kemerdekaan RI"
              value={formData.nama}
              onChange={(e) => setFormData({ ...formData, nama: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Tanggal</label>
            <input
              type="date"
              className="form-input"
              value={formData.tanggal}
              onChange={(e) => setFormData({ ...formData, tanggal: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Tipe Libur</label>
            <select
              className="form-select"
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
            >
              <option value="Libur Nasional">Libur Nasional</option>
              <option value="Cuti Bersama">Cuti Bersama</option>
              <option value="Libur Universitas">Libur Universitas / Dies Natalis</option>
            </select>
          </div>

          <div style={{ marginTop: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <input
              type="checkbox"
              id="is_national_create"
              checked={formData.is_national_holiday}
              onChange={(e) => setFormData({ ...formData, is_national_holiday: e.target.checked })}
              style={{ width: '16px', height: '16px', accentColor: 'var(--color-primary)' }}
            />
            <label htmlFor="is_national_create" style={{ fontSize: '0.875rem', fontWeight: 500, cursor: 'pointer' }}>
              Tetapkan sebagai Libur Nasional / Kalender Merah
            </label>
          </div>
        </form>
      </Modal>

      {/* Modal: Edit Hari Libur */}
      <Modal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        title="Ubah Master Hari Libur"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', width: '100%', gap: '12px' }}>
            <button className="btn btn-secondary" onClick={() => setIsEditModalOpen(false)}>
              Batal
            </button>
            <button className="btn btn-primary" onClick={handleEditSubmit}>
              Simpan Perubahan
            </button>
          </div>
        }
      >
        <form onSubmit={handleEditSubmit}>
          <div className="form-group">
            <label className="form-label">Nama Hari Libur</label>
            <input
              type="text"
              className="form-input"
              value={formData.nama}
              onChange={(e) => setFormData({ ...formData, nama: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Tanggal</label>
            <input
              type="date"
              className="form-input"
              value={formData.tanggal}
              onChange={(e) => setFormData({ ...formData, tanggal: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Tipe Libur</label>
            <select
              className="form-select"
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
            >
              <option value="Libur Nasional">Libur Nasional</option>
              <option value="Cuti Bersama">Cuti Bersama</option>
              <option value="Libur Universitas">Libur Universitas / Dies Natalis</option>
            </select>
          </div>

          <div style={{ marginTop: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <input
              type="checkbox"
              id="is_national_edit"
              checked={formData.is_national_holiday}
              onChange={(e) => setFormData({ ...formData, is_national_holiday: e.target.checked })}
              style={{ width: '16px', height: '16px', accentColor: 'var(--color-primary)' }}
            />
            <label htmlFor="is_national_edit" style={{ fontSize: '0.875rem', fontWeight: 500, cursor: 'pointer' }}>
              Tetapkan sebagai Libur Nasional / Kalender Merah
            </label>
          </div>
        </form>
      </Modal>

      {/* Modal: Hapus Hari Libur */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        title="Konfirmasi Hapus Hari Libur"
        maxWidth="440px"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', width: '100%', gap: '12px' }}>
            <button className="btn btn-secondary" onClick={() => setIsDeleteModalOpen(false)}>
              Batal
            </button>
            <button className="btn btn-danger" onClick={handleDeleteSubmit}>
              Ya, Hapus
            </button>
          </div>
        }
      >
        <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '10px',
              backgroundColor: '#fef2f2',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <AlertTriangle size={22} color="#ef4444" />
          </div>
          <div>
            <p style={{ fontWeight: 600, color: 'var(--text-main)' }}>
              Apakah Anda yakin ingin menghapus data libur ini?
            </p>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '4px' }}>
              "{selectedHoliday?.nama}" ({formatTanggalIndo(selectedHoliday?.tanggal)})
            </p>
          </div>
        </div>
      </Modal>
    </div>
  );
};
