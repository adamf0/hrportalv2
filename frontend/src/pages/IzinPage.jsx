import React, { useState, useEffect } from 'react';
import { 
  FileCheck, 
  Search, 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Paperclip, 
  Calendar
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';
import { Badge } from '../components/Badge';
import { Pagination } from '../components/Pagination';
import { formatTanggalIndo } from '../utils/date';

export const IzinPage = () => {
  const { showToast } = useToast();

  const [izinList, setIzinList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Detail / Action Modal State
  const [selectedIzin, setSelectedIzin] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [catatanSdm, setCatatanSdm] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchIzinList = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get('/api/izin');
      let list = [];
      if (Array.isArray(res)) {
        list = res;
      } else if (res?.data && Array.isArray(res.data)) {
        list = res.data;
      }
      setIzinList(list);
    } catch (err) {
      showToast(err.message || 'Gagal memuat data pengajuan izin', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIzinList();
  }, []);

  const handleOpenDetail = (item) => {
    setSelectedIzin(item);
    setCatatanSdm(item.catatan || item.catatan_sdm || '');
    setIsModalOpen(true);
  };

  const handleVerifyAction = async (newStatus) => {
    if (!selectedIzin) return;
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/izin/${selectedIzin.id}`, {
        status: newStatus,
        catatan: catatanSdm.trim(),
        role: 'sdm',
      });

      const actionText = newStatus === 'terima sdm' ? 'disetujui' : 'ditolak';
      showToast(`Pengajuan izin NIP ${selectedIzin.nip} berhasil ${actionText} oleh SDM!`, 'success');
      setIsModalOpen(false);
      fetchIzinList();
    } catch (err) {
      showToast(err.message || 'Gagal memproses verifikasi izin', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredList = izinList.filter((item) => {
    const status = (item.status || '').toLowerCase();
    const query = searchQuery.toLowerCase();
    const matchesSearch = 
      (item.nama_pemohon || item.nama || '').toLowerCase().includes(query) ||
      (item.nip || '').toLowerCase().includes(query) ||
      (item.unit || '').toLowerCase().includes(query) ||
      (item.fakultas || '').toLowerCase().includes(query) ||
      (item.prodi || '').toLowerCase().includes(query) ||
      (item.tujuan || item.keterangan || '').toLowerCase().includes(query);

    if (!matchesSearch) return false;

    if (activeFilter === 'pending') {
      return status.includes('menunggu') || status.includes('terima atasan') || status.includes('pending') || status === '';
    }
    if (activeFilter === 'approved') {
      return status.includes('terima sdm') || status.includes('disetujui') || status.includes('acc');
    }
    if (activeFilter === 'rejected') {
      return status.includes('tolak sdm') || status.includes('ditolak') || status.includes('tolak atasan');
    }
    return true;
  });

  const totalItems = filteredList.length;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedList = filteredList.slice(startIndex, startIndex + itemsPerPage);

  const handleFilterChange = (filterId) => {
    setActiveFilter(filterId);
    setCurrentPage(1);
  };

  const handleSearchChange = (val) => {
    setSearchQuery(val);
    setCurrentPage(1);
  };

  return (
    <div className="page-wrapper animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Verifikasi Pengajuan Izin</h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          Tinjau dan setujui / tolak pengajuan izin seluruh pegawai Universitas Pakuan (Khusus SDM)
        </p>
      </div>

      {/* Filter Tabs & Search */}
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
        {/* Status Tabs */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {[
            { id: 'all', label: 'Semua Status' },
            { id: 'pending', label: 'Menunggu Verifikasi SDM' },
            { id: 'approved', label: 'Disetujui SDM' },
            { id: 'rejected', label: 'Ditolak SDM' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => handleFilterChange(tab.id)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: activeFilter === tab.id ? 'var(--color-primary)' : '#f1f5f9',
                color: activeFilter === tab.id ? '#ffffff' : '#475569',
                fontWeight: 600,
                fontSize: '0.825rem',
                cursor: 'pointer',
                transition: 'all 0.15s',
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search */}
        <div style={{ position: 'relative', width: '100%', maxWidth: '320px' }}>
          <Search
            size={18}
            color="var(--text-muted)"
            style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }}
          />
          <input
            type="text"
            className="form-input"
            placeholder="Cari Pegawai, NIP, Unit, Fakultas..."
            value={searchQuery}
            onChange={(e) => handleSearchChange(e.target.value)}
            style={{ paddingLeft: '38px' }}
          />
        </div>
      </div>

      {/* Table with Pagination */}
      <div className="table-container">
        <table className="custom-table">
          <thead>
            <tr>
              <th style={{ width: '50px' }}>No</th>
              <th>Pegawai</th>
              <th>Unit Kerja</th>
              <th>Fakultas & Program Studi</th>
              <th>Tanggal Pengajuan</th>
              <th>Tujuan / Keperluan</th>
              <th>Status Saat Ini</th>
              <th style={{ width: '110px', textAlign: 'center' }}>Aksi SDM</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '40px' }}>
                  Memuat data permohonan izin...
                </td>
              </tr>
            ) : paginatedList.length === 0 ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                  Tidak ada data pengajuan izin pada kriteria filter ini.
                </td>
              </tr>
            ) : (
              paginatedList.map((item, index) => {
                const globalIndex = startIndex + index + 1;
                const nama = item.nama_pemohon || item.nama || '-';
                const tglIndo = formatTanggalIndo(item.tanggal_pengajuan || item.tanggal);
                return (
                  <tr key={item.id || index}>
                    <td style={{ fontWeight: 600, color: 'var(--text-muted)' }}>{globalIndex}</td>
                    <td>
                      <div style={{ fontWeight: 800, color: 'var(--text-main)' }}>{nama}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                        NIP: {item.nip}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.85rem', fontWeight: 600, color: '#334155' }}>
                        {item.unit || '-'}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.825rem', color: 'var(--text-main)' }}>
                        {item.fakultas || '-'}
                      </div>
                      {item.prodi && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '1px' }}>
                          Prodi: {item.prodi}
                        </div>
                      )}
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.825rem' }}>
                        <Calendar size={14} color="var(--text-muted)" />
                        <span style={{ fontWeight: 600 }}>{tglIndo}</span>
                      </div>
                    </td>
                    <td>
                      <div style={{ maxWidth: '240px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {item.tujuan || item.keterangan || '-'}
                      </div>
                    </td>
                    <td>
                      <Badge status={item.status} />
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <button
                        onClick={() => handleOpenDetail(item)}
                        className="btn btn-secondary btn-sm"
                        style={{ gap: '4px' }}
                      >
                        <Eye size={14} />
                        <span>Tinjau</span>
                      </button>
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

      {/* Modal: Tinjau & Verifikasi Izin SDM */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Tinjau Pengajuan Izin Pegawai"
        maxWidth="600px"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', width: '100%', gap: '12px' }}>
            <button
              className="btn btn-danger"
              onClick={() => handleVerifyAction('tolak sdm')}
              disabled={actionLoading}
            >
              <XCircle size={16} />
              <span>Tolak SDM</span>
            </button>
            <button
              className="btn btn-success"
              onClick={() => handleVerifyAction('terima sdm')}
              disabled={actionLoading}
            >
              <CheckCircle2 size={16} />
              <span>Terima SDM</span>
            </button>
          </div>
        }
      >
        {selectedIzin && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Applicant Card */}
            <div
              style={{
                backgroundColor: '#f8fafc',
                border: '1px solid var(--border-light)',
                borderRadius: '12px',
                padding: '16px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h4 style={{ fontSize: '1rem', fontWeight: 800 }}>{selectedIzin.nama_pemohon || selectedIzin.nama || selectedIzin.nip}</h4>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                    NIP: {selectedIzin.nip}
                  </p>
                  <p style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px' }}>
                    {[selectedIzin.fakultas, selectedIzin.prodi, selectedIzin.unit].filter(Boolean).join(' • ') || 'Pegawai Unpak'}
                  </p>
                </div>
                <Badge status={selectedIzin.status} />
              </div>
            </div>

            {/* Details Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}>Tanggal Izin</span>
                <p style={{ fontWeight: 700, fontSize: '0.875rem' }}>{formatTanggalIndo(selectedIzin.tanggal_pengajuan || selectedIzin.tanggal)}</p>
              </div>
              <div>
                <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}>Status Verifikasi Atasan</span>
                <p style={{ fontWeight: 600, fontSize: '0.875rem' }}>{selectedIzin.verifikasi ? `Disetujui NIP (${selectedIzin.verifikasi})` : 'Belum Diverifikasi'}</p>
              </div>
            </div>

            <div>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}>Tujuan / Keterangan</span>
              <p style={{ marginTop: '4px', fontSize: '0.875rem', backgroundColor: '#f8fafc', padding: '10px 12px', borderRadius: '8px' }}>
                {selectedIzin.tujuan || selectedIzin.keterangan || '-'}
              </p>
            </div>

            {selectedIzin.file_lampiran && (
              <div>
                <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}>Berkas Lampiran</span>
                <div style={{ marginTop: '4px' }}>
                  <a
                    href={selectedIzin.file_lampiran.startsWith('http') ? selectedIzin.file_lampiran : `${apiClient.baseUrl || ''}/${selectedIzin.file_lampiran}`}
                    target="_blank"
                    rel="noreferrer"
                    className="btn btn-secondary btn-sm"
                    style={{ display: 'inline-flex', gap: '6px' }}
                  >
                    <Paperclip size={14} />
                    <span>Unduh / Lihat Dokumen Lampiran</span>
                  </a>
                </div>
              </div>
            )}

            {/* SDM Decision Note */}
            <div className="form-group" style={{ marginTop: '8px' }}>
              <label className="form-label">Catatan Keputusan SDM (Opsional)</label>
              <textarea
                className="form-textarea"
                rows="3"
                placeholder="Tuliskan catatan alasan persetujuan / penolakan SDM jika ada..."
                value={catatanSdm}
                onChange={(e) => setCatatanSdm(e.target.value)}
              />
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
