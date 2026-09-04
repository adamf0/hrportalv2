import React, { useState, useEffect, useMemo } from 'react';
import { 
  CalendarClock, 
  Search, 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Paperclip, 
  Calendar,
  PlusCircle,
  FileText,
  UserCheck,
  Send,
  Clock,
  AlertTriangle,
  Info,
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

export const CutiPage = () => {
  const { user, userRole, isSdm, isBaum } = useAuth();
  const { showToast } = useToast();
  const isSdmOrBaum = isSdm || isBaum || userRole === 'sdm' || userRole === 'baum';

  const [activeTab, setActiveTab] = useState(isSdmOrBaum ? 'verifikasi' : 'pengajuan');
  const [cutiList, setCutiList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, statusFilter, activeTab, itemsPerPage]);

  useEffect(() => {
    if (isSdmOrBaum) {
      setActiveTab('verifikasi');
    } else {
      setActiveTab('pengajuan');
    }
  }, [userRole, isSdm, isBaum]);

  const [jenisCutiOptions, setJenisCutiOptions] = useState([]);

  useEffect(() => {
    const fetchMasterJenisCuti = async () => {
      try {
        const res = await apiClient.get('/api/v2/masterdata/jenis-cuti');
        let list = [];
        if (Array.isArray(res)) {
          list = res;
        } else if (res?.data && Array.isArray(res.data)) {
          list = res.data;
        }
        const options = list.map((item) => {
          const nameStr = item.nama || item.jenis_cuti || item.name || 'Cuti';
          const maxDays = item.max_hari || item.maks_hari || 12;
          const minDays = item.min_hari || 1;
          return {
            value: String(item.id),
            label: nameStr,
            name: nameStr,
            min_hari: minDays,
            max_hari: maxDays,
            subtitle: `Min: ${minDays} Hari • Max: ${maxDays} Hari`,
          };
        });
        setJenisCutiOptions(options);
      } catch (err) {
        console.error('Error fetching master jenis cuti:', err);
      }
    };
    fetchMasterJenisCuti();
  }, []);

  const getJenisCutiName = (item) => {
    if (!item) return '-';
    if (item.jenis_cuti && item.jenis_cuti.toLowerCase() !== 'cuti') {
      return item.jenis_cuti;
    }
    if (item.nama_jenis_cuti && item.nama_jenis_cuti.toLowerCase() !== 'cuti') {
      return item.nama_jenis_cuti;
    }
    const idStr = String(item.jenis_cuti_id || item.id_jenis_cuti || '');
    const found = jenisCutiOptions.find((o) => String(o.value) === idStr);
    if (found) return found.label;
    return item.jenis_cuti || 'Cuti Pegawai';
  };

  const [supervisorOptions, setSupervisorOptions] = useState([]);

  useEffect(() => {
    const fetchSupervisors = async () => {
      try {
        const res = await apiClient.get('/api/v2/masterdata/verifikator');
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

  // Form Pengajuan State (DEFAULT NULL AS REQUESTED)
  const [jenisCuti, setJenisCuti] = useState(null);
  const [tanggalMulai, setTanggalMulai] = useState('');
  const [tanggalSelesai, setTanggalSelesai] = useState('');
  const [lamaCutiHari, setLamaCutiHari] = useState(1);
  const [alasan, setAlasan] = useState('');
  const [nipAtasan, setNipAtasan] = useState(null);
  const [fileLampiran, setFileLampiran] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Selected Rule Info
  const selectedJenisCutiObj = jenisCutiOptions.find(o => String(o.value) === String(jenisCuti));

  // Auto calculate Lama Cuti whenever dates change
  useEffect(() => {
    if (tanggalMulai && tanggalSelesai) {
      const days = calculateDurationDays(tanggalMulai, tanggalSelesai);
      setLamaCutiHari(days);
    } else {
      setLamaCutiHari(1);
    }
  }, [tanggalMulai, tanggalSelesai]);

  // Rule Validation Check
  const isDurationValid = selectedJenisCutiObj
    ? (lamaCutiHari >= selectedJenisCutiObj.min_hari && lamaCutiHari <= selectedJenisCutiObj.max_hari)
    : true;

  // Detail / Action Modal State
  const [selectedCuti, setSelectedCuti] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [catatanSdm, setCatatanSdm] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchCutiList = async () => {
    setLoading(true);
    try {
      const isVerifTab = activeTab === 'verifikasi';
      const url = isVerifTab ? '/api/v2/leave/verifikasi' : '/api/v2/leave';
      const res = await apiClient.get(url);
      let list = [];
      if (Array.isArray(res)) {
        list = res;
      } else if (res?.data && Array.isArray(res.data)) {
        list = res.data;
      }
      setCutiList(list);
    } catch (err) {
      showToast(err.message || 'Gagal memuat data cuti', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setCurrentPage(1);
    fetchCutiList();
    const handleRoleChanged = () => {
      setCurrentPage(1);
      fetchCutiList();
    };
    window.addEventListener('role-changed', handleRoleChanged);
    return () => window.removeEventListener('role-changed', handleRoleChanged);
  }, [userRole, activeTab]);

  const [editingId, setEditingId] = useState(null);

  const handleResetForm = () => {
    setEditingId(null);
    setJenisCuti(null);
    setNipAtasan(null);
    setAlasan('');
    setTanggalMulai('');
    setTanggalSelesai('');
    setFileLampiran('');
  };

  const handleStartEdit = (item) => {
    setEditingId(item.id);
    setJenisCuti(String(item.jenis_cuti_id || item.id_jenis_cuti || '1'));
    setTanggalMulai(formatInputDate(item.tanggal_mulai || item.tanggal));
    setTanggalSelesai(formatInputDate(item.tanggal_selesai || item.tanggal_akhir || item.tanggal_mulai || item.tanggal));
    setAlasan(item.alasan || '');
    setNipAtasan(item.verifikasi || item.nip_atasan || null);
    showToast('Form diisi dengan data pengajuan. Silakan edit dan simpan.', 'info');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteCuti = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus pengajuan cuti ini?')) return;
    try {
      await apiClient.delete(`/api/v2/leave/${id}`);
      showToast('Pengajuan cuti berhasil dihapus.', 'success');
      fetchCutiList();
    } catch (err) {
      showToast(err.message || 'Gagal menghapus cuti', 'error');
    }
  };

  const handleSubmitLeave = async (e) => {
    e.preventDefault();
    if (!jenisCuti) {
      showToast('Harap pilih Jenis Cuti terlebih dahulu.', 'warning');
      return;
    }
    if (!nipAtasan) {
      showToast('Harap pilih NIP Atasan Verifikator terlebih dahulu.', 'warning');
      return;
    }
    if (!tanggalMulai || !tanggalSelesai || !alasan.trim()) {
      showToast('Harap lengkapi semua field yang wajib diisi.', 'warning');
      return;
    }

    if (!isDurationValid) {
      showToast(`Durasi cuti (${lamaCutiHari} Hari) tidak sesuai dengan batas aturan (${selectedJenisCutiObj?.min_hari} - ${selectedJenisCutiObj?.max_hari} Hari).`, 'error');
      return;
    }

    setSubmitting(true);
    try {
      if (editingId) {
        await apiClient.putForm(`/api/v2/leave/${editingId}`, {
          jenis_cuti_id: jenisCuti,
          tanggal_mulai: formatInputDate(tanggalMulai),
          tanggal_selesai: formatInputDate(tanggalSelesai),
          jumlah_hari: lamaCutiHari,
          alasan: alasan.trim(),
          nip_atasan: nipAtasan,
          verifikasi: nipAtasan,
          file_lampiran: fileLampiran,
        });
        showToast('Pengajuan cuti berhasil diperbarui!', 'success');
      } else {
        await apiClient.postForm('/api/v2/leave/submit', {
          nip: user?.nip || user?.username || '',
          nidn: user?.nidn || '',
          nama: user?.name || '',
          unit: user?.unit || '',
          fakultas: user?.fakultas || '',
          prodi: user?.prodi || '',
          jenis_cuti_id: jenisCuti,
          tanggal_mulai: formatInputDate(tanggalMulai),
          tanggal_selesai: formatInputDate(tanggalSelesai),
          jumlah_hari: lamaCutiHari,
          alasan: alasan.trim(),
          nip_atasan: nipAtasan,
          verifikasi: nipAtasan,
          file_lampiran: fileLampiran,
        });
        showToast('Pengajuan cuti berhasil dikirim!', 'success');
      }

      handleResetForm();
      fetchCutiList();
    } catch (err) {
      showToast(err.message || 'Gagal menyimpan pengajuan cuti', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
  const [selectedCutiForReject, setSelectedCutiForReject] = useState(null);
  const [alasanPenolakan, setAlasanPenolakan] = useState('');

  const handleApproveDirect = async (cutiItem) => {
    const statusToSet = isSdmOrBaum ? 'terima sdm' : 'terima atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/v2/leave/${cutiItem.id}`, {
        status: statusToSet,
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Pengajuan cuti berhasil disetujui (${statusToSet})`, 'success');
      fetchCutiList();
    } catch (err) {
      showToast(err.message || 'Gagal menyetujui cuti', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmReject = async () => {
    if (!selectedCutiForReject) return;
    if (!alasanPenolakan.trim()) {
      showToast('Harap masukkan alasan penolakan terlebih dahulu.', 'warning');
      return;
    }
    const statusToSet = isSdmOrBaum ? 'tolak sdm' : 'tolak atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/v2/leave/${selectedCutiForReject.id}`, {
        status: statusToSet,
        catatan_atasan: alasanPenolakan.trim(),
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Pengajuan cuti telah ditolak (${statusToSet})`, 'success');
      setIsRejectModalOpen(false);
      setAlasanPenolakan('');
      fetchCutiList();
    } catch (err) {
      showToast(err.message || 'Gagal menolak cuti', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const getItemStatusCategory = (item) => {
    const st = (item.status || '').toLowerCase().trim();
    if (st.includes('terima') || st.includes('setuju') || st.includes('acc') || st.includes('approved')) {
      return 'terima';
    }
    if (st.includes('tolak') || st.includes('reject')) {
      return 'tolak';
    }
    return 'menunggu';
  };

  const statusCounts = useMemo(() => {
    const baseList = cutiList.filter((item) => {
      const q = searchQuery.toLowerCase();
      const matchesSearch = (
        (item.nama_pemohon || item.nama || '').toLowerCase().includes(q) ||
        (item.nip || '').toLowerCase().includes(q) ||
        (item.alasan || '').toLowerCase().includes(q)
      );
      if (!matchesSearch) return false;
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
      return true;
    });

    const counts = { all: baseList.length, menunggu: 0, terima: 0, tolak: 0 };
    baseList.forEach((item) => {
      const cat = getItemStatusCategory(item);
      if (counts[cat] !== undefined) {
        counts[cat]++;
      }
    });
    return counts;
  }, [cutiList, searchQuery, isSdmOrBaum]);

  const filteredList = cutiList.filter((item) => {
    const q = searchQuery.toLowerCase();
    const matchesSearch = (
      (item.nama_pemohon || item.nama || '').toLowerCase().includes(q) ||
      (item.nip || '').toLowerCase().includes(q) ||
      (item.alasan || '').toLowerCase().includes(q)
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

    if (statusFilter !== 'all') {
      const cat = getItemStatusCategory(item);
      if (cat !== statusFilter) return false;
    }

    return true;
  });

  const renderStatusFilterTabs = () => (
    <div
      style={{
        display: 'inline-flex',
        gap: '4px',
        background: '#f3f4f6',
        padding: '4px',
        borderRadius: '24px',
        alignItems: 'center',
        maxWidth: '100%',
        overflowX: 'auto',
        whiteSpace: 'nowrap',
        scrollbarWidth: 'none',
        msOverflowStyle: 'none',
      }}
    >
      {[
        { key: 'all', label: 'Semua', activeBg: '#ffffff', activeColor: '#111827', badgeBg: '#e5e7eb' },
        { key: 'menunggu', label: 'Menunggu', activeBg: '#fffbe6', activeColor: '#d97706', badgeBg: '#fef08a' },
        { key: 'terima', label: 'Diterima', activeBg: '#ecfdf5', activeColor: '#059669', badgeBg: '#a7f3d0' },
        { key: 'tolak', label: 'Ditolak', activeBg: '#fef2f2', activeColor: '#dc2626', badgeBg: '#fca5a5' },
      ].map((tab) => {
        const isActive = statusFilter === tab.key;
        const count = statusCounts[tab.key] || 0;
        return (
          <button
            key={tab.key}
            type="button"
            onClick={() => { setStatusFilter(tab.key); setCurrentPage(1); }}
            style={{
              padding: '5px 12px',
              borderRadius: '20px',
              fontSize: '0.78rem',
              fontWeight: isActive ? 700 : 500,
              border: 'none',
              background: isActive ? tab.activeBg : 'transparent',
              color: isActive ? tab.activeColor : '#6b7280',
              boxShadow: isActive ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
              cursor: 'pointer',
              transition: 'all 0.15s ease',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              flexShrink: 0,
            }}
          >
            <span>{tab.label}</span>
            <span style={{
              fontSize: '0.7rem',
              padding: '1px 6px',
              borderRadius: '10px',
              background: isActive ? tab.badgeBg : '#e5e7eb',
              color: isActive ? tab.activeColor : '#4b5563',
              fontWeight: 700,
            }}>
              {count}
            </span>
          </button>
        );
      })}
    </div>
  );

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Header Banner */}
      <div
        className="bm-card"
        style={{
          padding: '24px 28px',
          background: 'linear-gradient(135deg, #faf5ff 0%, #ffffff 100%)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <span style={{ padding: '4px 10px', borderRadius: '4px', background: '#f3e8ff', color: '#7c3aed', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '6px', display: 'inline-block' }}>
            Manajemen Cuti Pegawai
          </span>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#111827' }}>
            Layanan &amp; Pengajuan Cuti
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '2px' }}>
            Pengajuan cuti tahunan, sakit, melahirkan, dan persetujuan verifikasi SDM.
          </p>
        </div>

        {/* Tab Switcher (Hided when active role is SDM / BAUM; Visible for Tendik / Dosen) */}
        {!isSdmOrBaum && (
          <div style={{ display: 'flex', gap: '4px', background: '#f7f8f6', padding: '4px', borderRadius: '8px', border: '1px solid #e5e7eb', maxWidth: '100%', boxSizing: 'border-box', overflowX: 'auto', scrollbarWidth: 'none' }}>
            <button
              onClick={() => setActiveTab('pengajuan')}
              style={{
                flex: '1 1 auto',
                padding: '8px 14px',
                borderRadius: '6px',
                border: 'none',
                background: activeTab === 'pengajuan' ? '#ffffff' : 'transparent',
                color: activeTab === 'pengajuan' ? '#111827' : '#6b7280',
                fontWeight: activeTab === 'pengajuan' ? 700 : 500,
                fontSize: '0.825rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                textAlign: 'center',
                flexShrink: 0,
                boxShadow: activeTab === 'pengajuan' ? '0 1px 2px rgba(0,0,0,0.05)' : 'none',
              }}
            >
              Form &amp; Riwayat Saya
            </button>
            <button
              onClick={() => setActiveTab('verifikasi')}
              style={{
                flex: '1 1 auto',
                padding: '8px 14px',
                borderRadius: '6px',
                border: 'none',
                background: activeTab === 'verifikasi' ? '#ffffff' : 'transparent',
                color: activeTab === 'verifikasi' ? '#111827' : '#6b7280',
                fontWeight: activeTab === 'verifikasi' ? 700 : 500,
                fontSize: '0.825rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                textAlign: 'center',
                flexShrink: 0,
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
          {/* Form Pengajuan Card */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <PlusCircle size={18} color="#7c3aed" />
                <span>{editingId ? 'Edit Permohonan Cuti' : 'Form Permohonan Cuti'}</span>
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

            <form onSubmit={handleSubmitLeave} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* JENIS CUTI - DEFAULT NULL */}
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Jenis Cuti *
                </label>
                <SearchableSelect
                  options={jenisCutiOptions}
                  value={jenisCuti}
                  onChange={(val) => setJenisCuti(val)}
                  placeholder="Pilih Jenis Cuti..."
                  searchPlaceholder="Ketik jenis cuti..."
                />
                {selectedJenisCutiObj && (
                  <div style={{ marginTop: '6px', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.775rem', color: '#6d28d9', background: '#f3e8ff', padding: '6px 12px', borderRadius: '8px' }}>
                    <Info size={14} />
                    <span>Ketentuan Hari: <strong>Min {selectedJenisCutiObj.min_hari} Hari</strong> &bull; <strong>Max {selectedJenisCutiObj.max_hari} Hari</strong></span>
                  </div>
                )}
              </div>

              {/* TANGGAL MULAI & SELESAI */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                    Mulai Tanggal *
                  </label>
                  <input type="date" className="bm-input" value={tanggalMulai} onChange={(e) => setTanggalMulai(e.target.value)} required />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                    Selesai Tanggal *
                  </label>
                  <input type="date" className="bm-input" value={tanggalSelesai} onChange={(e) => setTanggalSelesai(e.target.value)} required />
                </div>
              </div>

              {/* LAMA CUTI (JUMLAH HARI) */}
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Lama Cuti (Jumlah Hari) *
                </label>
                <div style={{ position: 'relative' }}>
                  <input
                    type="number"
                    min={1}
                    className="bm-input"
                    value={lamaCutiHari}
                    onChange={(e) => setLamaCutiHari(Number(e.target.value))}
                    style={{
                      fontWeight: 800,
                      color: isDurationValid ? '#111827' : '#dc2626',
                      borderColor: isDurationValid ? '#e2e8f0' : '#f87171',
                    }}
                    required
                  />
                  <span style={{ position: 'absolute', right: '14px', top: '50%', transform: 'translateY(-50%)', fontSize: '0.8rem', fontWeight: 700, color: '#6b7280' }}>
                    Hari
                  </span>
                </div>

                {!isDurationValid && selectedJenisCutiObj && (
                  <div style={{ marginTop: '6px', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.775rem', color: '#b91c1c', background: '#fef2f2', padding: '6px 12px', borderRadius: '8px', border: '1px solid #fecaca' }}>
                    <AlertTriangle size={14} />
                    <span>Perhatian: Durasi ({lamaCutiHari} Hari) di luar ketentuan batas {selectedJenisCutiObj.min_hari} - {selectedJenisCutiObj.max_hari} Hari!</span>
                  </div>
                )}
              </div>

              {/* NIP ATASAN VERIFIKATOR - DEFAULT NULL */}
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  NIP Atasan Verifikator *
                </label>
                <SearchableSelect
                  options={supervisorOptions}
                  value={nipAtasan}
                  onChange={(val) => setNipAtasan(val)}
                  placeholder="Pilih NIP / Nama Atasan Verifikator..."
                  searchPlaceholder="Ketik NIP atau Nama Atasan..."
                />
              </div>

              {/* ALASAN CUTI */}
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Alasan Permohonan Cuti *
                </label>
                <textarea className="bm-input" rows={3} placeholder="Keterangan cuti..." value={alasan} onChange={(e) => setAlasan(e.target.value)} required />
              </div>

              <button
                type="submit"
                disabled={submitting || !isDurationValid || !jenisCuti || !nipAtasan}
                className="bm-btn-emerald"
                style={{
                  background: (isDurationValid && jenisCuti && nipAtasan) ? '#7c3aed' : '#9ca3af',
                  padding: '12px',
                  justifyContent: 'center',
                  fontWeight: 800,
                  cursor: (isDurationValid && jenisCuti && nipAtasan) ? 'pointer' : 'not-allowed',
                }}
              >
                <Send size={16} />
                <span>{submitting ? 'Mengirim...' : editingId ? 'Simpan Perubahan Cuti' : 'Kirim Pengajuan Cuti'}</span>
              </button>
            </form>
          </div>

          {/* Riwayat Pengajuan Saya */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '12px' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', margin: 0 }}>
                Riwayat Pengajuan Cuti
              </h2>
              {renderStatusFilterTabs()}
            </div>

            {loading ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>Memuat riwayat...</div>
            ) : filteredList.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280', background: '#f9fafb', borderRadius: '8px', border: '1px solid #e5e7eb' }}>
                Belum ada pengajuan cuti.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '500px', overflowY: 'auto' }}>
                {filteredList.map((item, idx) => {
                  const duration = item.jumlah_hari || calculateDurationDays(item.tanggal_mulai, item.tanggal_selesai);
                  return (
                    <div key={idx} style={{ padding: '14px 16px', borderRadius: '10px', background: '#f9fafb', border: '1px solid #e5e7eb' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                        <span style={{ fontWeight: 700, color: '#111827', fontSize: '0.9rem' }}>
                          {getJenisCutiName(item)}
                        </span>
                        <Badge variant={(item.status || '').toLowerCase().includes('terima') ? 'success' : (item.status || '').toLowerCase().includes('tolak') ? 'danger' : 'warning'}>
                          {item.status || 'Menunggu'}
                        </Badge>
                      </div>

                      <div style={{ fontSize: '0.825rem', color: '#7c3aed', fontWeight: 700, marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span>📅 {formatIndonesianDateRange(item.tanggal_mulai || item.tanggal, item.tanggal_selesai || item.tanggal_akhir || item.tanggal_mulai || item.tanggal, false)}</span>
                        <span style={{ background: '#f3e8ff', color: '#7c3aed', padding: '3px 10px', borderRadius: '16px', fontSize: '0.75rem', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}>
                          <Clock size={12} />
                          <span>{duration} Hari</span>
                        </span>
                      </div>

                      <div style={{ fontSize: '0.8rem', color: '#6b7280', marginBottom: '8px' }}>
                        Alasan: {item.alasan}
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
                          onClick={() => handleDeleteCuti(item.id)}
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
                  );
                })}
              </div>
            )}
          </div>
        </div>
      ) : (
        /* Tabel Verifikasi SDM Admin */
        <div className="bm-card" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', margin: 0 }}>
                Verifikasi Permohonan Cuti Pegawai (SDM Admin)
              </h2>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', width: '100%' }}>
              {renderStatusFilterTabs()}
              <div style={{ position: 'relative', minWidth: '200px', flex: '1 1 200px', maxWidth: '320px' }}>
                <Search size={15} color="#9ca3af" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
                <input type="text" className="bm-input" placeholder="Cari nama/NIP..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} style={{ paddingLeft: '36px', height: '36px', width: '100%' }} />
              </div>
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e5e7eb', color: '#6b7280' }}>
                  <th style={{ padding: '12px 16px' }}>Pemohon</th>
                  <th style={{ padding: '12px 16px' }}>Jenis &amp; Tanggal Cuti</th>
                  <th style={{ padding: '12px 16px' }}>Lama Cuti</th>
                  <th style={{ padding: '12px 16px' }}>Alasan</th>
                  <th style={{ padding: '12px 16px' }}>Status</th>
                  <th style={{ padding: '12px 16px' }}>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredList.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((item, idx) => {
                  const duration = item.jumlah_hari || calculateDurationDays(item.tanggal_mulai, item.tanggal_selesai);
                  return (
                    <tr key={idx} style={{ borderBottom: '1px solid #f3f4f6' }}>
                      <td style={{ padding: '14px 16px', fontWeight: 600, color: '#111827' }}>
                        {item.nama_pemohon || item.nama || 'Pegawai UNPAK'}
                        <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>NIP: {item.nip}</div>
                      </td>
                      <td style={{ padding: '14px 16px', color: '#7c3aed', fontWeight: 600 }}>
                        {getJenisCutiName(item)}
                        <div style={{ fontSize: '0.775rem', color: '#6b7280', fontWeight: 500 }}>
                          {formatIndonesianDateRange(item.tanggal_mulai, item.tanggal_selesai, false)}
                        </div>
                      </td>
                      <td style={{ padding: '14px 16px', whiteSpace: 'nowrap' }}>
                        <span style={{ padding: '4px 10px', borderRadius: '16px', background: '#f3e8ff', color: '#7c3aed', fontWeight: 700, fontSize: '0.78rem', display: 'inline-flex', alignItems: 'center', gap: '5px', whiteSpace: 'nowrap' }}>
                          <Clock size={13} />
                          <span>{duration} Hari</span>
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', color: '#4b5563' }}>{item.alasan}</td>
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
                              setSelectedCutiForReject(item);
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
                  );
                })}
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
        title={isSdmOrBaum ? "Konfirmasi Penolakan Cuti (SDM Admin)" : "Konfirmasi Penolakan Cuti (Atasan)"}
      >
        {selectedCutiForReject && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ background: '#fef2f2', padding: '14px', borderRadius: '8px', border: '1px solid #fecaca' }}>
              <div style={{ fontWeight: 700, color: '#991b1b', fontSize: '0.9rem' }}>
                Pemohon: {selectedCutiForReject.nama_pemohon && selectedCutiForReject.nama_pemohon !== 'sdm' ? selectedCutiForReject.nama_pemohon : (selectedCutiForReject.nama && selectedCutiForReject.nama !== 'sdm' ? selectedCutiForReject.nama : 'Pegawai UNPAK')} (NIP: {selectedCutiForReject.nip})
              </div>
              <div style={{ fontSize: '0.85rem', color: '#b91c1c', marginTop: '4px', fontWeight: 600 }}>
                Jenis: {getJenisCutiName(selectedCutiForReject)} ({selectedCutiForReject.jumlah_hari || calculateDurationDays(selectedCutiForReject.tanggal_mulai, selectedCutiForReject.tanggal_selesai)} Hari)
              </div>
              <div style={{ fontSize: '0.825rem', color: '#991b1b', marginTop: '4px', fontWeight: 500 }}>
                📅 Tanggal: {formatIndonesianDateRange(selectedCutiForReject.tanggal_mulai, selectedCutiForReject.tanggal_selesai, false)}
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
                placeholder="Masukkan alasan mengapa pengajuan cuti ini ditolak..."
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
