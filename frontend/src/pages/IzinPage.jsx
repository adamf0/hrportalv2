import React, { useState, useEffect } from 'react';
import { 
  FileCheck, 
  Search, 
  PlusCircle, 
  Send,
  Calendar,
  UserCheck,
  AlertCircle,
  Clock,
  Edit3,
  Trash2,
  X
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import { Modal } from '../components/Modal';
import { Badge } from '../components/Badge';
import { SearchableSelect } from '../components/SearchableSelect';
import { formatIndonesianDate, formatIndonesianDateRange, calculateDurationDays, formatInputDate } from '../utils/dateFormatter';

import { Pagination } from '../components/Pagination';

export const IzinPage = () => {
  const { user, userRole, isSdm, isBaum } = useAuth();
  const { showToast } = useToast();
  const isSdmOrBaum = isSdm || isBaum || userRole === 'sdm' || userRole === 'baum';

  const [activeTab, setActiveTab] = useState(isSdmOrBaum ? 'verifikasi' : 'pengajuan');
  const [izinList, setIzinList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, activeTab, itemsPerPage]);

  useEffect(() => {
    if (isSdmOrBaum) {
      setActiveTab('verifikasi');
    } else {
      setActiveTab('pengajuan');
    }
  }, [userRole, isSdm, isBaum]);

  const [jenisIzinOptions, setJenisIzinOptions] = useState([]);

  useEffect(() => {
    const fetchMasterJenisIzin = async () => {
      try {
        const res = await apiClient.get('/api/masterdata/jenis-izin');
        let list = [];
        if (Array.isArray(res)) {
          list = res;
        } else if (res?.data && Array.isArray(res.data)) {
          list = res.data;
        }
        const options = list.map((item) => ({
          value: String(item.id),
          label: item.nama || item.jenis_izin || item.name || 'Izin',
          name: item.nama || item.jenis_izin || item.name || 'Izin',
          subtitle: item.deskripsi || item.subtitle || 'Kategori Permohonan Izin',
        }));
        setJenisIzinOptions(options);
      } catch (err) {
        console.error('Error fetching master jenis izin:', err);
      }
    };
    fetchMasterJenisIzin();
  }, []);

  const [supervisorOptions, setSupervisorOptions] = useState([]);

  useEffect(() => {
    const fetchSupervisors = async () => {
      try {
        const res = await apiClient.get('/api/masterdata/verifikator');
        let list = [];
        if (Array.isArray(res)) {
          list = res;
        } else if (res?.data && Array.isArray(res.data)) {
          list = res.data;
        }
        const options = list.map((item) => {
          const nipStr = item.nip || item.Nip || item.value || '';
          const nameStr = item.nama || item.Nama || item.label || 'Pegawai';
          const jabatanStr = item.struktural || item.jabatan || item.unit || item.subtitle || '';
          return {
            value: nipStr,
            nip: nipStr,
            label: nameStr,
            name: nameStr,
            subtitle: jabatanStr ? `NIP: ${nipStr} • ${jabatanStr}` : `NIP: ${nipStr}`,
          };
        });
        setSupervisorOptions(options);
      } catch (err) {
        console.error('Error fetching supervisors from backend:', err);
      }
    };
    fetchSupervisors();
  }, []);

  // Form State (DEFAULT NULL AS REQUESTED)
  const [jenisIzin, setJenisIzin] = useState(null);
  const [tanggalPengajuan, setTanggalPengajuan] = useState('');
  const [tujuan, setTujuan] = useState('');
  const [verifikasi, setVerifikasi] = useState(null);
  const [fileLampiran, setFileLampiran] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Modal Verifikasi State
  const [selectedIzin, setSelectedIzin] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [catatan, setCatatan] = useState('');
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
      showToast('Gagal memuat data permohonan izin', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setCurrentPage(1);
    fetchIzinList();
    const handleRoleChanged = () => {
      setCurrentPage(1);
      fetchIzinList();
    };
    window.addEventListener('role-changed', handleRoleChanged);
    return () => window.removeEventListener('role-changed', handleRoleChanged);
  }, [userRole]);

  const [editingId, setEditingId] = useState(null);

  const handleResetForm = () => {
    setEditingId(null);
    setJenisIzin(null);
    setVerifikasi(null);
    setTujuan('');
    setTanggalPengajuan('');
    setFileLampiran('');
  };

  const handleStartEdit = (item) => {
    setEditingId(item.id);
    setJenisIzin(String(item.jenis_izin_id || item.id_jenis_izin || '1'));
    setTanggalPengajuan(formatInputDate(item.tanggal_pengajuan || item.tanggal_mulai || item.tanggal));
    setTujuan(item.tujuan || item.alasan || '');
    setVerifikasi(item.verifikasi || item.nip_atasan || null);
    showToast('Form diisi dengan data permohonan. Silakan edit dan simpan.', 'info');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteIzin = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus pengajuan izin ini?')) return;
    try {
      await apiClient.delete(`/api/izin/${id}`);
      showToast('Pengajuan izin berhasil dihapus.', 'success');
      fetchIzinList();
    } catch (err) {
      showToast(err.message || 'Gagal menghapus izin', 'error');
    }
  };

  const handleSubmitIzin = async (e) => {
    e.preventDefault();
    if (!jenisIzin) {
      showToast('Harap pilih Kategori Izin terlebih dahulu.', 'warning');
      return;
    }
    if (!verifikasi) {
      showToast('Harap pilih NIP Atasan Verifikator terlebih dahulu.', 'warning');
      return;
    }
    if (!tanggalPengajuan || !tujuan.trim()) {
      showToast('Harap lengkapi tanggal dan alasan tujuan izin.', 'warning');
      return;
    }

    setSubmitting(true);
    try {
      if (editingId) {
        await apiClient.putForm(`/api/izin/${editingId}`, {
          id_jenis_izin: jenisIzin,
          tanggal_pengajuan: formatInputDate(tanggalPengajuan),
          tujuan: tujuan.trim(),
          verifikasi: verifikasi,
          file_lampiran: fileLampiran,
        });
        showToast('Pengajuan izin berhasil diperbarui!', 'success');
      } else {
        await apiClient.postForm('/api/izin', {
          nip: user?.nip || user?.username || '',
          nidn: user?.nidn || '',
          nama: user?.name || '',
          unit: user?.unit || '',
          fakultas: user?.fakultas || '',
          prodi: user?.prodi || '',
          id_jenis_izin: jenisIzin,
          tanggal_pengajuan: formatInputDate(tanggalPengajuan),
          tujuan: tujuan.trim(),
          verifikasi: verifikasi,
          file_lampiran: fileLampiran,
        });
        showToast('Pengajuan izin berhasil dikirim!', 'success');
      }

      handleResetForm();
      fetchIzinList();
    } catch (err) {
      showToast(err.message || 'Gagal menyimpan pengajuan izin', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
  const [selectedIzinForReject, setSelectedIzinForReject] = useState(null);
  const [alasanPenolakan, setAlasanPenolakan] = useState('');

  const handleApproveDirect = async (izinItem) => {
    const statusToSet = isSdmOrBaum ? 'terima sdm' : 'terima atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/izin/${izinItem.id}`, {
        status: statusToSet,
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Permohonan izin berhasil disetujui (${statusToSet})`, 'success');
      fetchIzinList();
    } catch (err) {
      showToast(err.message || 'Gagal menyetujui izin', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmReject = async () => {
    if (!selectedIzinForReject) return;
    if (!alasanPenolakan.trim()) {
      showToast('Harap masukkan alasan penolakan terlebih dahulu.', 'warning');
      return;
    }
    const statusToSet = isSdmOrBaum ? 'tolak sdm' : 'tolak atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/izin/${selectedIzinForReject.id}`, {
        status: statusToSet,
        catatan: alasanPenolakan.trim(),
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Permohonan izin telah ditolak (${statusToSet})`, 'success');
      setIsRejectModalOpen(false);
      setAlasanPenolakan('');
      fetchIzinList();
    } catch (err) {
      showToast(err.message || 'Gagal menolak izin', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredList = izinList.filter((item) => {
    const q = searchQuery.toLowerCase();
    const matchesSearch = (
      (item.nama || item.nama_pemohon || '').toLowerCase().includes(q) ||
      (item.nip || '').toLowerCase().includes(q) ||
      (item.tujuan || '').toLowerCase().includes(q)
    );

    if (!matchesSearch) return false;

    // Filter status for SDM / BAUM mode: only show terima atasan, terima sdm, tolak sdm
    if (isSdmOrBaum) {
      const st = (item.status || '').toLowerCase().trim();
      const isAllowedSdmStatus = 
        st.includes('terima atasan') ||
        st.includes('terima sdm') ||
        st.includes('tolak sdm') ||
        st.includes('disetujui atasan') ||
        st.includes('disetujui sdm') ||
        st.includes('ditolak sdm') ||
        st.includes('acc atasan') ||
        st.includes('acc sdm') ||
        st.includes('proses sdm');

      if (!isAllowedSdmStatus) return false;
    }

    // In Tendik/Dosen mode, when on Verifikasi Atasan tab, match supervisor verifikasi NIP/username
    if (!isSdmOrBaum && activeTab === 'verifikasi') {
      const userNip = (user?.nip || user?.username || '').toLowerCase();
      const verifNip = (item.verifikasi || item.nip_atasan || '').toLowerCase();
      return verifNip && verifNip === userNip;
    }

    return true;
  });

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header Banner */}
      <div
        className="bm-card"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, #f0f9ff 0%, #ffffff 100%)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <span style={{ padding: '4px 10px', borderRadius: '4px', background: '#e0f2fe', color: '#0284c7', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '6px', display: 'inline-block' }}>
            Manajemen Izin Pegawai
          </span>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#111827' }}>
            Layanan &amp; Pengajuan Izin
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '2px' }}>
            Pengajuan permohonan izin meninggalkan tugas / sakit dan verifikasi SDM.
          </p>
        </div>

        {/* Tab Switcher (Hided when active role is SDM / BAUM; Visible for Tendik / Dosen) */}
        {!isSdmOrBaum && (
          <div style={{ display: 'flex', gap: '4px', background: '#f7f8f6', padding: '4px', borderRadius: '8px', border: '1px solid #e5e7eb' }}>
            <button
              onClick={() => setActiveTab('pengajuan')}
              style={{
                padding: '8px 16px',
                borderRadius: '6px',
                border: 'none',
                background: activeTab === 'pengajuan' ? '#ffffff' : 'transparent',
                color: activeTab === 'pengajuan' ? '#111827' : '#6b7280',
                fontWeight: activeTab === 'pengajuan' ? 700 : 500,
                fontSize: '0.825rem',
                cursor: 'pointer',
                boxShadow: activeTab === 'pengajuan' ? '0 1px 2px rgba(0,0,0,0.05)' : 'none',
              }}
            >
              Form &amp; Riwayat Saya
            </button>
            <button
              onClick={() => setActiveTab('verifikasi')}
              style={{
                padding: '8px 16px',
                borderRadius: '6px',
                border: 'none',
                background: activeTab === 'verifikasi' ? '#ffffff' : 'transparent',
                color: activeTab === 'verifikasi' ? '#111827' : '#6b7280',
                fontWeight: activeTab === 'verifikasi' ? 700 : 500,
                fontSize: '0.825rem',
                cursor: 'pointer',
                boxShadow: activeTab === 'verifikasi' ? '0 1px 2px rgba(0,0,0,0.05)' : 'none',
              }}
            >
              Verifikasi Atasan
            </button>
          </div>
        )}
      </div>

      {activeTab === 'pengajuan' ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px' }}>
          {/* Form Permohonan Izin */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <PlusCircle size={18} color="#0284c7" />
                <span>{editingId ? 'Edit Permohonan Izin' : 'Form Permohonan Izin'}</span>
              </div>
              {editingId && (
                <button
                  type="button"
                  onClick={handleResetForm}
                  style={{
                    fontSize: '0.75rem',
                    background: '#f3f4f6',
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    padding: '3px 8px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    color: '#374151',
                    fontWeight: 700,
                  }}
                >
                  <X size={14} />
                  Batal Edit
                </button>
              )}
            </h2>

            <form onSubmit={handleSubmitIzin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Kategori Izin *
                </label>
                <SearchableSelect
                  options={jenisIzinOptions}
                  value={jenisIzin}
                  onChange={(val) => setJenisIzin(val)}
                  placeholder="Pilih Kategori Izin..."
                  searchPlaceholder="Ketik jenis izin..."
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Tanggal Permohonan Izin *
                </label>
                <input type="date" className="bm-input" value={tanggalPengajuan} onChange={(e) => setTanggalPengajuan(e.target.value)} required />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  NIP Atasan Verifikator *
                </label>
                <SearchableSelect
                  options={supervisorOptions}
                  value={verifikasi}
                  onChange={(val) => setVerifikasi(val)}
                  placeholder="Pilih NIP / Nama Atasan Verifikator..."
                  searchPlaceholder="Ketik NIP atau Nama Atasan..."
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Keterangan / Tujuan Izin *
                </label>
                <textarea className="bm-input" rows={3} placeholder="Tuliskan keperluan izin..." value={tujuan} onChange={(e) => setTujuan(e.target.value)} required />
              </div>

              <button
                type="submit"
                disabled={submitting || !jenisIzin || !verifikasi}
                className="bm-btn-emerald"
                style={{
                  background: (jenisIzin && verifikasi) ? '#0284c7' : '#9ca3af',
                  padding: '12px',
                  justifyContent: 'center',
                  fontWeight: 800,
                  cursor: (jenisIzin && verifikasi) ? 'pointer' : 'not-allowed',
                }}
              >
                <Send size={16} />
                <span>{submitting ? 'Mengirim...' : editingId ? 'Simpan Perubahan Izin' : 'Kirim Pengajuan Izin'}</span>
              </button>
            </form>
          </div>

          {/* Riwayat Izin Saya */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', marginBottom: '16px' }}>
              Riwayat Izin Saya
            </h2>

            {loading ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>Memuat riwayat...</div>
            ) : filteredList.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280', background: '#f9fafb', borderRadius: '8px', border: '1px solid #e5e7eb' }}>
                Belum ada permohonan izin.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '500px', overflowY: 'auto' }}>
                {filteredList.map((item, idx) => (
                  <div key={idx} style={{ padding: '14px 16px', borderRadius: '10px', background: '#f9fafb', border: '1px solid #e5e7eb' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                      <span style={{ fontWeight: 700, color: '#111827', fontSize: '0.9rem' }}>
                        Izin Pegawai
                      </span>
                      <Badge variant={(item.status || '').toLowerCase().includes('terima') ? 'success' : (item.status || '').toLowerCase().includes('tolak') ? 'danger' : 'warning'}>
                        {item.status || 'Menunggu'}
                      </Badge>
                    </div>
                    <div style={{ fontSize: '0.825rem', color: '#0284c7', fontWeight: 700, marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span>📅 {formatIndonesianDateRange(item.tanggal_pengajuan || item.tanggal, item.tanggal_pengajuan || item.tanggal, false)}</span>
                      <span style={{ background: '#e0f2fe', color: '#0369a1', padding: '2px 8px', borderRadius: '9999px', fontSize: '0.725rem', fontWeight: 800 }}>
                        1 Hari Izin
                      </span>
                    </div>
                    <div style={{ fontSize: '0.8rem', color: '#6b7280', marginBottom: '8px' }}>
                      Keterangan: {item.tujuan || item.alasan}
                    </div>

                    {/* Always show Edit and Hapus buttons regardless of status */}
                    <div style={{ display: 'flex', gap: '8px', borderTop: '1px solid #e5e7eb', paddingTop: '10px', marginTop: '6px' }}>
                      <button
                        type="button"
                        onClick={() => handleStartEdit(item)}
                        style={{
                          padding: '4px 10px',
                          fontSize: '0.75rem',
                          background: '#ffffff',
                          border: '1px solid #cbd5e1',
                          borderRadius: '6px',
                          color: '#0284c7',
                          fontWeight: 700,
                          cursor: 'pointer',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <Edit3 size={13} />
                        Edit
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteIzin(item.id)}
                        style={{
                          padding: '4px 10px',
                          fontSize: '0.75rem',
                          background: '#ffffff',
                          border: '1px solid #fecaca',
                          borderRadius: '6px',
                          color: '#dc2626',
                          fontWeight: 700,
                          cursor: 'pointer',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <Trash2 size={13} />
                        Hapus
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      ) : (
        /* Tabel Verifikasi SDM Admin */
        <div className="bm-card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827' }}>
              Verifikasi Permohonan Izin Pegawai (SDM Admin)
            </h2>
            <div style={{ position: 'relative', minWidth: '240px' }}>
              <Search size={15} color="#9ca3af" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input type="text" className="bm-input" placeholder="Cari nama/NIP..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} style={{ paddingLeft: '36px', height: '36px' }} />
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e5e7eb', color: '#6b7280' }}>
                  <th style={{ padding: '12px 16px' }}>Pemohon</th>
                  <th style={{ padding: '12px 16px' }}>Tanggal Izin</th>
                  <th style={{ padding: '12px 16px' }}>Lama Izin</th>
                  <th style={{ padding: '12px 16px' }}>Keterangan / Tujuan</th>
                  <th style={{ padding: '12px 16px' }}>Status</th>
                  <th style={{ padding: '12px 16px' }}>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredList.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((item, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid #f3f4f6' }}>
                    <td style={{ padding: '14px 16px', fontWeight: 600, color: '#111827' }}>
                      {item.nama || item.nama_pemohon || 'Pegawai UNPAK'}
                      <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>NIP: {item.nip}</div>
                    </td>
                    <td style={{ padding: '14px 16px', color: '#0284c7', fontWeight: 700 }}>
                      {formatIndonesianDate(item.tanggal_pengajuan || item.tanggal)}
                    </td>
                    <td style={{ padding: '14px 16px' }}>
                      <span style={{ padding: '4px 10px', borderRadius: '9999px', background: '#e0f2fe', color: '#0369a1', fontWeight: 800, fontSize: '0.775rem', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                        <Clock size={12} />
                        1 Hari
                      </span>
                    </td>
                    <td style={{ padding: '14px 16px', color: '#4b5563' }}>{item.tujuan}</td>
                    <td style={{ padding: '14px 16px' }}>
                      <Badge variant={(item.status || '').toLowerCase().includes('terima') ? 'success' : (item.status || '').toLowerCase().includes('tolak') ? 'danger' : 'warning'}>
                        {item.status || 'Menunggu'}
                      </Badge>
                    </td>
                    <td style={{ padding: '14px 16px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <button
                          onClick={() => handleApproveDirect(item)}
                          disabled={actionLoading}
                          className="bm-btn-emerald"
                          style={{ padding: '6px 12px', fontSize: '0.775rem', whiteSpace: 'nowrap' }}
                        >
                          {isSdmOrBaum ? 'Terima SDM' : 'Terima'}
                        </button>
                        <button
                          onClick={() => {
                            setSelectedIzinForReject(item);
                            setAlasanPenolakan('');
                            setIsRejectModalOpen(true);
                          }}
                          disabled={actionLoading}
                          style={{
                            padding: '6px 12px',
                            fontSize: '0.775rem',
                            background: '#ef4444',
                            color: '#ffffff',
                            borderRadius: '8px',
                            border: 'none',
                            fontWeight: 700,
                            cursor: 'pointer',
                            whiteSpace: 'nowrap',
                            transition: 'all 0.15s ease',
                          }}
                        >
                          {isSdmOrBaum ? 'Tolak SDM' : 'Tolak'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            currentPage={currentPage}
            totalItems={filteredList.length}
            itemsPerPage={itemsPerPage}
            onPageChange={(page) => setCurrentPage(page)}
            onItemsPerPageChange={(size) => {
              setItemsPerPage(size);
              setCurrentPage(1);
            }}
          />
        </div>
      )}

      {/* Modal Alasan Penolakan */}
      <Modal
        isOpen={isRejectModalOpen}
        onClose={() => setIsRejectModalOpen(false)}
        title={isSdmOrBaum ? "Konfirmasi Penolakan Izin (SDM Admin)" : "Konfirmasi Penolakan Izin (Atasan)"}
      >
        {selectedIzinForReject && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ background: '#fef2f2', padding: '14px', borderRadius: '8px', border: '1px solid #fecaca' }}>
              <div style={{ fontWeight: 700, color: '#991b1b', fontSize: '0.9rem' }}>
                Pemohon: {selectedIzinForReject.nama && selectedIzinForReject.nama !== 'sdm' ? selectedIzinForReject.nama : (selectedIzinForReject.nama_pemohon && selectedIzinForReject.nama_pemohon !== 'sdm' ? selectedIzinForReject.nama_pemohon : 'Pegawai UNPAK')} (NIP: {selectedIzinForReject.nip})
              </div>
              <div style={{ fontSize: '0.85rem', color: '#b91c1c', marginTop: '4px', fontWeight: 600 }}>
                Keterangan: {selectedIzinForReject.tujuan || 'Izin Pegawai'} (1 Hari)
              </div>
              <div style={{ fontSize: '0.825rem', color: '#991b1b', marginTop: '4px', fontWeight: 500 }}>
                📅 Tanggal: {formatIndonesianDate(selectedIzinForReject.tanggal_pengajuan || selectedIzinForReject.tanggal)}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.825rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                Alasan Penolakan *
              </label>
              <textarea
                className="bm-input"
                rows={4}
                value={alasanPenolakan}
                onChange={(e) => setAlasanPenolakan(e.target.value)}
                placeholder="Masukkan alasan mengapa permohonan izin ini ditolak..."
                required
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '8px' }}>
              <button
                type="button"
                onClick={() => setIsRejectModalOpen(false)}
                style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', background: '#ffffff', color: '#475569', fontWeight: 700, cursor: 'pointer' }}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmReject}
                disabled={actionLoading || !alasanPenolakan.trim()}
                style={{
                  padding: '8px 16px',
                  borderRadius: '8px',
                  border: 'none',
                  background: (alasanPenolakan.trim()) ? '#dc2626' : '#9ca3af',
                  color: '#ffffff',
                  fontWeight: 800,
                  cursor: (alasanPenolakan.trim()) ? 'pointer' : 'not-allowed',
                }}
              >
                {actionLoading ? 'Memproses...' : 'Kirim Penolakan'}
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
