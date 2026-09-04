import React, { useState, useEffect, useMemo } from 'react';
import { 
  PlaneTakeoff, 
  Search, 
  PlusCircle, 
  Send,
  Users,
  Calendar,
  FileText,
  UserCheck,
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
import { formatIndonesianDateRange, calculateDurationDays, formatInputDate } from '../utils/dateFormatter';

import { Pagination } from '../components/Pagination';

export const SppdPage = () => {
  const { user, userRole, isSdm, isBaum } = useAuth();
  const { showToast } = useToast();
  const isSdmOrBaum = isSdm || isBaum || userRole === 'sdm' || userRole === 'baum';

  const [activeTab, setActiveTab] = useState(isSdmOrBaum ? 'verifikasi' : 'pengajuan');
  const [sppdList, setSppdList] = useState([]);
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

  const [jenisSppdOptions, setJenisSppdOptions] = useState([]);

  useEffect(() => {
    const fetchMasterJenisSppd = async () => {
      try {
        const res = await apiClient.get('/api/v2/masterdata/jenis-sppd');
        let list = [];
        if (Array.isArray(res)) {
          list = res;
        } else if (res?.data && Array.isArray(res.data)) {
          list = res.data;
        }
        const options = list.map((item) => ({
          value: String(item.id),
          label: item.nama || item.jenis_sppd || item.name || 'SPPD',
          name: item.nama || item.jenis_sppd || item.name || 'SPPD',
          subtitle: item.deskripsi || item.subtitle || 'Kategori Perjalanan Dinas',
        }));
        setJenisSppdOptions(options);
      } catch (err) {
        console.error('Error fetching master jenis sppd:', err);
      }
    };
    fetchMasterJenisSppd();
  }, []);

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

  const [peopleOptions, setPeopleOptions] = useState([]);

  useEffect(() => {
    const fetchPeople = async () => {
      try {
        const res = await apiClient.get('/api/v2/masterdata/people');
        let list = [];
        if (Array.isArray(res)) {
          list = res;
        } else if (res?.data && Array.isArray(res.data)) {
          list = res.data;
        }
        const options = list.map((item) => {
          const nipStr = item.nip || item.Nip || item.value || '';
          const nameStr = item.nama || item.Nama || item.label || item.name || 'Pegawai';
          const jabatanStr = item.unit || item.struktural || item.jabatan || item.subtitle || '';
          return {
            value: nipStr,
            nip: nipStr,
            label: nameStr,
            name: nameStr,
            subtitle: jabatanStr.startsWith('NIP:') ? jabatanStr : (jabatanStr ? `NIP: ${nipStr} • ${jabatanStr}` : `NIP: ${nipStr}`),
          };
        });
        setPeopleOptions(options);
      } catch (err) {
        console.error('Error fetching people masterdata from backend:', err);
      }
    };
    fetchPeople();
  }, []);

  // Form State (DEFAULT NULL AS REQUESTED)
  const [jenisSppd, setJenisSppd] = useState(null);
  const [tanggalBerangkat, setTanggalBerangkat] = useState('');
  const [tanggalKembali, setTanggalKembali] = useState('');
  const [tujuan, setTujuan] = useState('');
  const [keterangan, setKeterangan] = useState('');
  const [verifikasi, setVerifikasi] = useState(null);
  const [anggotaNama, setAnggotaNama] = useState('');
  const [anggotaNip, setAnggotaNip] = useState('');
  const [anggotaList, setAnggotaList] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  // Modal Verifikasi State
  const [selectedSppd, setSelectedSppd] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [catatanSdm, setCatatanSdm] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchSppdList = async () => {
    setLoading(true);
    try {
      const isVerifTab = activeTab === 'verifikasi';
      const url = isVerifTab ? '/api/v2/sppd/verifikasi' : '/api/v2/sppd/history';
      const res = await apiClient.get(url);
      let list = [];
      if (Array.isArray(res)) {
        list = res;
      } else if (res?.data && Array.isArray(res.data)) {
        list = res.data;
      }
      setSppdList(list);
    } catch (err) {
      showToast('Gagal memuat data pengajuan SPPD', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setCurrentPage(1);
    fetchSppdList();
    const handleRoleChanged = () => {
      setCurrentPage(1);
      fetchSppdList();
    };
    window.addEventListener('role-changed', handleRoleChanged);
    return () => window.removeEventListener('role-changed', handleRoleChanged);
  }, [userRole, activeTab]);

  const [selectedAnggotaOption, setSelectedAnggotaOption] = useState(null);

  const handleSelectAnggotaMember = (selectedVal) => {
    if (!selectedVal) return;
    const allOptions = [...peopleOptions, ...supervisorOptions];
    const foundOpt = allOptions.find((o) => String(o.value) === String(selectedVal));
    if (!foundOpt) return;

    const exists = anggotaList.some((m) => String(m.nip || m.nama) === String(foundOpt.nip || foundOpt.name));
    if (exists) {
      showToast(`${foundOpt.name} sudah ada dalam daftar anggota rombongan.`, 'warning');
      setSelectedAnggotaOption(null);
      return;
    }

    setAnggotaList([
      ...anggotaList,
      {
        nip: foundOpt.nip || '',
        nama: foundOpt.name || foundOpt.label || '',
        unit: foundOpt.subtitle || '',
      },
    ]);
    showToast(`Berhasil menambahkan ${foundOpt.name} ke rombongan.`, 'success');
    setSelectedAnggotaOption(null);
  };

  const handleAddMember = () => {
    if (!anggotaNama.trim()) return;
    setAnggotaList([...anggotaList, { nip: anggotaNip.trim(), nama: anggotaNama.trim(), unit: '' }]);
    setAnggotaNama('');
    setAnggotaNip('');
  };

  const handleRemoveMember = (index) => {
    setAnggotaList(anggotaList.filter((_, i) => i !== index));
  };

  const [editingId, setEditingId] = useState(null);

  const handleResetForm = () => {
    setEditingId(null);
    setJenisSppd(null);
    setVerifikasi(null);
    setTujuan('');
    setKeterangan('');
    setTanggalBerangkat('');
    setTanggalKembali('');
    setAnggotaList([]);
  };

  const handleStartEdit = (item) => {
    setEditingId(item.id);
    setJenisSppd(String(item.jenis_sppd_id || item.id_jenis_sppd || '1'));
    setTanggalBerangkat(formatInputDate(item.tanggal_berangkat || item.tanggal_mulai || item.tanggal));
    setTanggalKembali(formatInputDate(item.tanggal_kembali || item.tanggal_akhir || item.tanggal_selesai || item.tanggal_berangkat));
    setTujuan(item.tujuan || '');
    setKeterangan(item.keterangan || '');
    setVerifikasi(item.verifikasi || item.nip_atasan || null);
    showToast('Form diisi dengan data SPPD. Silakan edit dan simpan.', 'info');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteSppd = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus pengajuan SPPD ini?')) return;
    try {
      await apiClient.delete(`/api/v2/sppd/${id}`);
      showToast('Pengajuan SPPD berhasil dihapus.', 'success');
      fetchSppdList();
    } catch (err) {
      showToast(err.message || 'Gagal menghapus SPPD', 'error');
    }
  };

  const handleSubmitSppd = async (e) => {
    e.preventDefault();
    if (!jenisSppd) {
      showToast('Harap pilih Jenis SPPD terlebih dahulu.', 'warning');
      return;
    }
    if (!verifikasi) {
      showToast('Harap pilih NIP Atasan Verifikator terlebih dahulu.', 'warning');
      return;
    }
    if (!tanggalBerangkat || !tanggalKembali || !tujuan.trim()) {
      showToast('Harap lengkapi tanggal berangkat, tanggal kembali, dan tujuan tugas.', 'warning');
      return;
    }

    setSubmitting(true);
    try {
      if (editingId) {
        await apiClient.putForm(`/api/v2/sppd/${editingId}`, {
          jenis_sppd_id: jenisSppd,
          tanggal_berangkat: formatInputDate(tanggalBerangkat),
          tanggal_kembali: formatInputDate(tanggalKembali),
          tujuan: tujuan.trim(),
          keterangan: `Atasan: ${verifikasi} | ${keterangan.trim()}`,
          verifikasi: verifikasi,
          anggota: JSON.stringify(anggotaList),
        });
        showToast('Pengajuan SPPD berhasil diperbarui!', 'success');
      } else {
        await apiClient.postForm('/api/v2/sppd/create', {
          nip: user?.nip || user?.username || '',
          nidn: user?.nidn || '',
          nama: user?.name || '',
          unit: user?.unit || '',
          fakultas: user?.fakultas || '',
          prodi: user?.prodi || '',
          jenis_sppd_id: jenisSppd,
          tanggal_berangkat: formatInputDate(tanggalBerangkat),
          tanggal_kembali: formatInputDate(tanggalKembali),
          tujuan: tujuan.trim(),
          keterangan: `Atasan: ${verifikasi} | ${keterangan.trim()}`,
          verifikasi: verifikasi,
          anggota: JSON.stringify(anggotaList),
        });
        showToast('Pengajuan SPPD berhasil dikirim!', 'success');
      }

      handleResetForm();
      fetchSppdList();
    } catch (err) {
      showToast(err.message || 'Gagal menyimpan SPPD', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);
  const [selectedSppdForReject, setSelectedSppdForReject] = useState(null);
  const [alasanPenolakan, setAlasanPenolakan] = useState('');

  const handleApproveDirect = async (sppdItem) => {
    const statusToSet = isSdmOrBaum ? 'terima sdm' : 'terima atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/v2/sppd/${sppdItem.id}`, {
        status: statusToSet,
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Pengajuan SPPD berhasil disetujui (${statusToSet})`, 'success');
      fetchSppdList();
    } catch (err) {
      showToast(err.message || 'Gagal menyetujui SPPD', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmReject = async () => {
    if (!selectedSppdForReject) return;
    if (!alasanPenolakan.trim()) {
      showToast('Harap masukkan alasan penolakan terlebih dahulu.', 'warning');
      return;
    }
    const statusToSet = isSdmOrBaum ? 'tolak sdm' : 'tolak atasan';
    setActionLoading(true);

    try {
      await apiClient.putForm(`/api/v2/sppd/${selectedSppdForReject.id}`, {
        status: statusToSet,
        catatan: alasanPenolakan.trim(),
        role: isSdmOrBaum ? 'sdm' : 'atasan',
      });

      showToast(`Pengajuan SPPD telah ditolak (${statusToSet})`, 'success');
      setIsRejectModalOpen(false);
      setAlasanPenolakan('');
      fetchSppdList();
    } catch (err) {
      showToast(err.message || 'Gagal menolak SPPD', 'error');
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
    const baseList = sppdList.filter((item) => {
      const q = searchQuery.toLowerCase();
      const matchesSearch = (
        (item.nama_pemohon || item.nama || '').toLowerCase().includes(q) ||
        (item.nip || '').toLowerCase().includes(q) ||
        (item.tujuan || '').toLowerCase().includes(q)
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
  }, [sppdList, searchQuery, isSdmOrBaum]);

  const filteredList = sppdList.filter((item) => {
    const q = searchQuery.toLowerCase();
    const matchesSearch = (
      (item.nama_pemohon || item.nama || '').toLowerCase().includes(q) ||
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
          background: 'linear-gradient(135deg, #e0e7ff 0%, #ffffff 100%)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <span style={{ padding: '4px 10px', borderRadius: '4px', background: '#c7d2fe', color: '#4338ca', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '6px', display: 'inline-block' }}>
            Perjalanan Dinas (SPPD)
          </span>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#111827' }}>
            Layanan &amp; Pengajuan SPPD
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#6b7280', marginTop: '2px' }}>
            Pengajuan Surat Perintah Perjalanan Dinas dalam &amp; luar kota beserta anggota rombongan.
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
          {/* Form Permohonan SPPD */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', marginBottom: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <PlusCircle size={18} color="#4f46e5" />
                <span>{editingId ? 'Edit Pengajuan SPPD' : 'Form Pengajuan SPPD'}</span>
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

            <form onSubmit={handleSubmitSppd} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Jenis Dinas / SPPD *
                </label>
                <SearchableSelect
                  options={jenisSppdOptions}
                  value={jenisSppd}
                  onChange={(val) => setJenisSppd(val)}
                  placeholder="Pilih Jenis SPPD..."
                  searchPlaceholder="Ketik jenis SPPD..."
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                    Tgl Berangkat *
                  </label>
                  <input type="date" className="bm-input" value={tanggalBerangkat} onChange={(e) => setTanggalBerangkat(e.target.value)} required />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                    Tgl Kembali *
                  </label>
                  <input type="date" className="bm-input" value={tanggalKembali} onChange={(e) => setTanggalKembali(e.target.value)} required />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>
                  Kota / Tempat Tujuan Dinas *
                </label>
                <input type="text" className="bm-input" value={tujuan} onChange={(e) => setTujuan(e.target.value)} placeholder="Contoh: Bandung / Jakarta..." required />
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
                  Keterangan / Maksud Perjalanan Dinas
                </label>
                <textarea className="bm-input" rows={2} placeholder="Maksud tugas dinas..." value={keterangan} onChange={(e) => setKeterangan(e.target.value)} />
              </div>

              {/* Anggota Rombongan Tim (Searchable Select from Backend Masterdata) */}
              <div style={{ borderTop: '1px solid #e5e7eb', paddingTop: '14px' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#4f46e5', marginBottom: '8px' }}>
                  Anggota Rombongan Tim (Opsional)
                </label>

                {/* Searchable Select from Backend Masterdata */}
                <div style={{ marginBottom: '10px' }}>
                  <SearchableSelect
                    options={peopleOptions.length > 0 ? peopleOptions : supervisorOptions}
                    value={selectedAnggotaOption}
                    onChange={(val) => handleSelectAnggotaMember(val)}
                    placeholder="Search & pilih nama / NIP anggota rombongan..."
                    searchPlaceholder="Ketik nama atau NIP pegawai..."
                  />
                </div>

                {/* Badges List Anggota Terpilih */}
                {anggotaList.length > 0 && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '10px' }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#4b5563' }}>
                      Daftar Anggota Terpilih ({anggotaList.length} orang):
                    </span>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                      {anggotaList.map((m, i) => (
                        <span
                          key={i}
                          style={{
                            padding: '6px 12px',
                            borderRadius: '8px',
                            background: '#e0e7ff',
                            border: '1px solid #c7d2fe',
                            fontSize: '0.75rem',
                            color: '#3730a3',
                            fontWeight: 700,
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '6px',
                          }}
                        >
                          👤 {m.nama} {m.nip ? `(${m.nip})` : ''}
                          <button
                            type="button"
                            onClick={() => handleRemoveMember(i)}
                            style={{
                              background: '#ef4444',
                              border: 'none',
                              color: '#ffffff',
                              borderRadius: '9999px',
                              width: '16px',
                              height: '16px',
                              fontSize: '0.75rem',
                              cursor: 'pointer',
                              display: 'inline-flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              lineHeight: 1,
                              fontWeight: 800,
                              marginLeft: '2px',
                            }}
                            title="Hapus Anggota"
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <button
                type="submit"
                disabled={submitting || !jenisSppd || !verifikasi}
                className="bm-btn-emerald"
                style={{
                  background: (jenisSppd && verifikasi) ? '#4f46e5' : '#9ca3af',
                  padding: '12px',
                  justifyContent: 'center',
                  fontWeight: 800,
                  cursor: (jenisSppd && verifikasi) ? 'pointer' : 'not-allowed',
                }}
              >
                <Send size={16} />
                <span>{submitting ? 'Mengirim...' : editingId ? 'Simpan Perubahan SPPD' : 'Kirim Pengajuan SPPD'}</span>
              </button>
            </form>
          </div>

          {/* Riwayat SPPD Saya */}
          <div className="bm-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '12px' }}>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827', margin: 0 }}>
                Riwayat SPPD Saya
              </h2>
              {renderStatusFilterTabs()}
            </div>

            {loading ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>Memuat riwayat...</div>
            ) : filteredList.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280', background: '#f9fafb', borderRadius: '8px', border: '1px solid #e5e7eb' }}>
                Belum ada pengajuan SPPD.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '500px', overflowY: 'auto' }}>
                {filteredList.map((item, idx) => {
                  const duration = calculateDurationDays(item.tanggal_berangkat, item.tanggal_kembali);
                  return (
                    <div key={idx} style={{ padding: '14px 16px', borderRadius: '10px', background: '#f9fafb', border: '1px solid #e5e7eb' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                        <span style={{ fontWeight: 700, color: '#111827', fontSize: '0.9rem' }}>
                          Tujuan: {item.tujuan || 'Perjalanan Dinas'}
                        </span>
                        <Badge variant={(item.status || '').toLowerCase().includes('terima') ? 'success' : (item.status || '').toLowerCase().includes('tolak') ? 'danger' : 'warning'}>
                          {item.status || 'Menunggu'}
                        </Badge>
                      </div>
                      <div style={{ fontSize: '0.825rem', color: '#4f46e5', fontWeight: 700, marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span>✈️ {formatIndonesianDateRange(item.tanggal_berangkat || item.tanggal_mulai || item.tanggal, item.tanggal_kembali || item.tanggal_akhir || item.tanggal_selesai || item.tanggal_berangkat, false)}</span>
                        <span style={{ background: '#e0e7ff', color: '#4338ca', padding: '3px 10px', borderRadius: '16px', fontSize: '0.75rem', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}>
                          <Clock size={12} />
                          <span>{duration} Hari</span>
                        </span>
                      </div>
                      <div style={{ fontSize: '0.8rem', color: '#6b7280', marginBottom: '8px' }}>
                        Keterangan: {item.keterangan || '-'}
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
                          onClick={() => handleDeleteSppd(item.id)}
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
                Verifikasi Pengajuan SPPD Pegawai (SDM Admin)
              </h2>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', width: '100%' }}>
              {renderStatusFilterTabs()}
              <div style={{ position: 'relative', minWidth: '200px', flex: '1 1 200px', maxWidth: '320px' }}>
                <Search size={15} color="#9ca3af" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
                <input type="text" className="bm-input" placeholder="Cari nama/tujuan..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} style={{ paddingLeft: '36px', height: '36px', width: '100%' }} />
              </div>
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #e5e7eb', color: '#6b7280' }}>
                  <th style={{ padding: '12px 16px' }}>Pemohon</th>
                  <th style={{ padding: '12px 16px' }}>Tujuan &amp; Tanggal SPPD</th>
                  <th style={{ padding: '12px 16px' }}>Lama Perjalanan</th>
                  <th style={{ padding: '12px 16px' }}>Keterangan</th>
                  <th style={{ padding: '12px 16px' }}>Status</th>
                  <th style={{ padding: '12px 16px' }}>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredList.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((item, idx) => {
                  const duration = calculateDurationDays(item.tanggal_berangkat, item.tanggal_kembali);
                  return (
                    <tr key={idx} style={{ borderBottom: '1px solid #f3f4f6' }}>
                      <td style={{ padding: '14px 16px', fontWeight: 600, color: '#111827' }}>
                        {item.nama_pemohon || item.nama || 'Pegawai UNPAK'}
                        <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>NIP: {item.nip}</div>
                      </td>
                      <td style={{ padding: '14px 16px', color: '#4f46e5', fontWeight: 600 }}>
                        {item.tujuan}
                        <div style={{ fontSize: '0.775rem', color: '#6b7280', fontWeight: 500 }}>
                          {formatIndonesianDateRange(item.tanggal_berangkat, item.tanggal_kembali, false)}
                        </div>
                      </td>
                      <td style={{ padding: '14px 16px', whiteSpace: 'nowrap' }}>
                        <span style={{ padding: '4px 10px', borderRadius: '16px', background: '#e0e7ff', color: '#4338ca', fontWeight: 700, fontSize: '0.78rem', display: 'inline-flex', alignItems: 'center', gap: '5px', whiteSpace: 'nowrap' }}>
                          <Clock size={13} />
                          <span>{duration} Hari</span>
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', color: '#4b5563' }}>{item.keterangan}</td>
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
                              setSelectedSppdForReject(item);
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
        title={isSdmOrBaum ? "Konfirmasi Penolakan SPPD (SDM Admin)" : "Konfirmasi Penolakan SPPD (Atasan)"}
      >
        {selectedSppdForReject && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ background: '#fef2f2', padding: '14px', borderRadius: '8px', border: '1px solid #fecaca' }}>
              <div style={{ fontWeight: 700, color: '#991b1b', fontSize: '0.9rem' }}>
                Pemohon: {selectedSppdForReject.nama_pemohon && selectedSppdForReject.nama_pemohon !== 'sdm' ? selectedSppdForReject.nama_pemohon : (selectedSppdForReject.nama && selectedSppdForReject.nama !== 'sdm' ? selectedSppdForReject.nama : 'Pegawai UNPAK')} (NIP: {selectedSppdForReject.nip})
              </div>
              <div style={{ fontSize: '0.85rem', color: '#b91c1c', marginTop: '4px', fontWeight: 600 }}>
                Tujuan: {selectedSppdForReject.tujuan || 'Perjalanan Dinas'} ({calculateDurationDays(selectedSppdForReject.tanggal_berangkat, selectedSppdForReject.tanggal_kembali)} Hari)
              </div>
              <div style={{ fontSize: '0.825rem', color: '#991b1b', marginTop: '4px', fontWeight: 500 }}>
                📅 Tanggal: {formatIndonesianDateRange(selectedSppdForReject.tanggal_berangkat, selectedSppdForReject.tanggal_kembali, false)}
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
                placeholder="Masukkan alasan mengapa pengajuan SPPD ini ditolak..."
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
