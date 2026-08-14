import React, { useState, useEffect, useMemo } from 'react';
import { 
  FileSpreadsheet, 
  Search, 
  Download, 
  Calendar, 
  RefreshCw, 
  Award, 
  Filter,
  Building,
  GraduationCap
} from 'lucide-react';
import { apiClient } from '../api/client';
import { useToast } from '../components/Toast';
import { Pagination } from '../components/Pagination';
import { Modal } from '../components/Modal';
import { formatTanggalIndo } from '../utils/date';

const BULAN_LIST = [
  { value: 1, name: 'Januari', short: 'Jan' },
  { value: 2, name: 'Februari', short: 'Feb' },
  { value: 3, name: 'Maret', short: 'Mar' },
  { value: 4, name: 'April', short: 'Apr' },
  { value: 5, name: 'Mei', short: 'Mei' },
  { value: 6, name: 'Juni', short: 'Jun' },
  { value: 7, name: 'Juli', short: 'Jul' },
  { value: 8, name: 'Agustus', short: 'Agu' },
  { value: 9, name: 'September', short: 'Sep' },
  { value: 10, name: 'Oktober', short: 'Okt' },
  { value: 11, name: 'November', short: 'Nov' },
  { value: 12, name: 'Desember', short: 'Des' },
];

const TAHUN_LIST = [2023, 2024, 2025, 2026, 2027];

const formatJamMasuk = (str) => {
  if (!str) return '';
  if (str.includes(' ')) {
    const timePart = str.split(' ')[1];
    return timePart.substring(0, 5);
  }
  if (str.includes('T')) {
    const timePart = str.split('T')[1];
    if (timePart.startsWith('00:00')) return '07:00';
    return timePart.substring(0, 5);
  }
  if (str.length >= 5) {
    return str.substring(0, 5);
  }
  return str;
};

export const ReportPage = () => {
  const { showToast } = useToast();

  // Top-level Navigation Tab: 'presensi' (Reguler Bulanan) vs 'upacara' (Presensi Upacara Tahunan)
  const [mainReportTab, setMainReportTab] = useState('presensi');

  const now = new Date();
  const [selectedMonth, setSelectedMonth] = useState(now.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(now.getFullYear());
  const [periodType, setPeriodType] = useState('calendar'); // 'calendar' (1-31) or 'cutoff' (16-15) for Presensi tab

  // Filter States: Fakultas, Prodi, Unit, Search Query
  const [selectedFakultas, setSelectedFakultas] = useState('');
  const [selectedProdi, setSelectedProdi] = useState('');
  const [selectedUnit, setSelectedUnit] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  // Master Data States
  const [fakultasList, setFakultasList] = useState([]);
  const [prodiList, setProdiList] = useState([]);

  // Data States
  const [loading, setLoading] = useState(true);
  const [rawEmployees, setRawEmployees] = useState([]);
  const [holidays, setHolidays] = useState(new Set());
  const [ceremonyList, setCeremonyList] = useState([]);

  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Cell Detail Modal State
  const [selectedCell, setSelectedCell] = useState(null);
  const [isCellModalOpen, setIsCellModalOpen] = useState(false);

  // Export State
  const [isExporting, setIsExporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);

  // Fetch Master Data Fakultas & Prodi from https://hrportal.unpak.ac.id/api/v2/masterdata/fakultas & prodi
  useEffect(() => {
    const fetchMasterData = async () => {
      try {
        // 1. Fetch Fakultas from https://hrportal.unpak.ac.id/api/v2/masterdata/fakultas
        let fakData = [];
        try {
          const resFak = await apiClient.get('/unpak-api/masterdata/fakultas');
          fakData = Array.isArray(resFak) ? resFak : (resFak?.data || resFak?.list_data || []);
        } catch (e) {
          const localFak = await apiClient.get('/api/masterdata/fakultas').catch(() => []);
          fakData = Array.isArray(localFak) ? localFak : (localFak?.data || localFak?.list_data || []);
        }

        // 2. Fetch Prodi from https://hrportal.unpak.ac.id/api/v2/masterdata/prodi
        let prodData = [];
        try {
          const resProd = await apiClient.get('/unpak-api/masterdata/prodi');
          prodData = Array.isArray(resProd) ? resProd : (resProd?.data || resProd?.list_data || []);
        } catch (e) {
          const localProd = await apiClient.get('/api/masterdata/prodi').catch(() => []);
          prodData = Array.isArray(localProd) ? localProd : (localProd?.data || localProd?.list_data || []);
        }

        setFakultasList(fakData.filter(f => f && (f.nama || f.nama_fakultas || f.fakultas || f.kode)));
        setProdiList(prodData.filter(p => p && (p.nama || p.nama_prodi || p.prodi || p.kode)));
      } catch (err) {
        console.warn('Gagal memuat masterdata:', err);
      }
    };

    fetchMasterData();
  }, []);

  // Compute start & end date strings based on selected period
  const getPeriodDates = () => {
    if (mainReportTab === 'upacara') {
      return {
        startStr: `${selectedYear}-01-01`,
        endStr: `${selectedYear}-12-31`,
        daysInPeriod: 365,
        startDay: 1,
      };
    }

    if (periodType === 'calendar') {
      const lastDay = new Date(selectedYear, selectedMonth, 0).getDate();
      const pad = (n) => String(n).padStart(2, '0');
      const startStr = `${selectedYear}-${pad(selectedMonth)}-01`;
      const endStr = `${selectedYear}-${pad(selectedMonth)}-${pad(lastDay)}`;
      return { startStr, endStr, daysInPeriod: lastDay, startDay: 1 };
    } else {
      // Cutoff 16 prev month to 15 this month
      const prevYear = selectedMonth === 1 ? selectedYear - 1 : selectedYear;
      const prevMonth = selectedMonth === 1 ? 12 : selectedMonth - 1;
      const pad = (n) => String(n).padStart(2, '0');
      const startStr = `${prevYear}-${pad(prevMonth)}-16`;
      const endStr = `${selectedYear}-${pad(selectedMonth)}-15`;
      return { startStr, endStr, daysInPeriod: 31, startDay: 16 };
    }
  };

  const getDatesList = () => {
    const { startStr, endStr } = getPeriodDates();
    const dates = [];
    const curr = new Date(startStr);
    const end = new Date(endStr);
    while (curr <= end) {
      dates.push(new Date(curr));
      curr.setDate(curr.getDate() + 1);
    }
    return dates;
  };

  const fetchAllData = async () => {
    setLoading(true);
    const { startStr, endStr } = getPeriodDates();
    try {
      const [reportRes, holidayRes, ceremonyRes] = await Promise.allSettled([
        apiClient.get('/api/laporan/all', {
          tanggal_mulai: startStr,
          tanggal_akhir: endStr,
        }),
        apiClient.get('/api/holiday', { year: selectedYear }),
        apiClient.get('/api/ceremony-attendance'),
      ]);

      let empList = [];
      if (reportRes.status === 'fulfilled' && reportRes.value) {
        const val = reportRes.value;
        if (val.list_data && Array.isArray(val.list_data)) {
          empList = val.list_data;
        } else if (val.pegawai && Array.isArray(val.pegawai)) {
          empList = val.pegawai;
        } else if (Array.isArray(val)) {
          empList = val;
        } else if (val.data && Array.isArray(val.data)) {
          empList = val.data;
        }
      }

      const holidaySet = new Set();
      if (holidayRes.status === 'fulfilled' && holidayRes.value) {
        const hList = Array.isArray(holidayRes.value) ? holidayRes.value : (holidayRes.value?.data || []);
        hList.forEach((h) => {
          if (h.tanggal) {
            holidaySet.add(h.tanggal.split('T')[0]);
          }
        });
      }

      let cList = [];
      if (ceremonyRes.status === 'fulfilled' && ceremonyRes.value) {
        const val = ceremonyRes.value;
        if (Array.isArray(val)) {
          cList = val;
        } else if (val.data && Array.isArray(val.data)) {
          cList = val.data;
        }
      }

      setHolidays(holidaySet);
      setRawEmployees(empList);
      setCeremonyList(cList);
    } catch (err) {
      showToast(err.message || 'Gagal memuat rekap data laporan', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
    setCurrentPage(1);
  }, [mainReportTab, selectedMonth, selectedYear, periodType]);

  // Extract unique Units from dataset for filter
  const uniqueUnits = useMemo(() => {
    const set = new Set();
    rawEmployees.forEach((item) => {
      const p = item.pengguna || {};
      const u = p.unit || p.unit_kerja;
      if (u && u.trim() && u.trim() !== '-') set.add(u.trim());
    });
    return Array.from(set).sort();
  }, [rawEmployees]);

  // Filtered employees by Search, Fakultas, Prodi, and Unit
  const filteredEmployees = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    return rawEmployees.filter((item) => {
      const p = item.pengguna || {};
      const nip = (p.nip || item.kode || '').toLowerCase();
      const nama = (p.nama || '').toLowerCase();
      const unit = (p.unit_kerja || p.unit || '').toLowerCase();
      const fakultas = (p.fakultas || '').toLowerCase();
      const prodi = (p.prodi || '').toLowerCase();

      // Search Query
      if (q && !nama.includes(q) && !nip.includes(q) && !unit.includes(q) && !fakultas.includes(q) && !prodi.includes(q)) {
        return false;
      }

      // Fakultas Filter
      if (selectedFakultas && !fakultas.includes(selectedFakultas.toLowerCase())) {
        return false;
      }

      // Prodi Filter
      if (selectedProdi && !prodi.includes(selectedProdi.toLowerCase())) {
        return false;
      }

      // Unit Filter
      if (selectedUnit && !unit.includes(selectedUnit.toLowerCase())) {
        return false;
      }

      return true;
    });
  }, [rawEmployees, searchQuery, selectedFakultas, selectedProdi, selectedUnit]);

  const handleExportExcel = () => {
    if (mainReportTab === 'presensi') {
      exportPresensiCSV();
    } else {
      exportCeremonyYearlyCSV();
    }
  };

  const exportPresensiCSV = () => {
    try {
      const dates = getDatesList();
      const monthName = BULAN_LIST.find((b) => b.value === selectedMonth)?.name || selectedMonth;
      const periodLabel = periodType === 'calendar' ? 'Bulan_Penuh' : 'Cutoff_Payroll';

      const dateHeaders = dates.map((d) => {
        const day = d.getDate();
        const m = d.getMonth() + 1;
        return `${day}/${m}`;
      });

      const headers = [
        'No',
        'NIP',
        'Nama Pegawai',
        'Unit Kerja',
        'Fakultas',
        'Prodi',
        'Total Hadir',
        ...dateHeaders,
      ];

      const rows = filteredEmployees.map((item, idx) => {
        const p = item.pengguna || {};
        const nip = p.nip || item.kode || '';
        const nama = p.nama || `Pegawai ${nip}`;
        const unit = p.unit_kerja || p.unit || '';
        const fak = p.fakultas || '';
        const prd = p.prodi || '';
        const records = item.records || [];

        const totalHadir = records.filter((r) => r.type === 'absen' && r.info?.masuk).length;

        const dayValues = dates.map((d) => {
          const dKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
          const isSunday = d.getDay() === 0;
          const isHoliday = holidays.has(dKey);

          const rec = getRecordForDate(records, dKey);
          if (rec) {
            if (rec.type === 'absen') {
              return `"${formatJamMasuk(rec.info?.masuk) || 'Hadir'}"`;
            } else if (rec.type === 'izin') {
              return '"Izin"';
            } else if (rec.type === 'cuti') {
              return '"Cuti"';
            } else if (rec.type === 'sppd') {
              return '"SPPD"';
            }
          }

          if (isSunday || isHoliday) {
            return '"Libur"';
          }

          return '"-"';
        });

        return [
          idx + 1,
          `"${nip}"`,
          `"${nama.replace(/"/g, '""')}"`,
          `"${unit.replace(/"/g, '""')}"`,
          `"${fak.replace(/"/g, '""')}"`,
          `"${prd.replace(/"/g, '""')}"`,
          totalHadir,
          ...dayValues,
        ].join(',');
      });

      const csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(','), ...rows].join('\n');
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement('a');
      link.setAttribute('href', encodedUri);
      link.setAttribute('download', `Laporan_Presensi_${monthName}_${selectedYear}_${periodLabel}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      showToast(`File Laporan Presensi ${monthName} ${selectedYear} berhasil diunduh!`, 'success');
    } catch (e) {
      console.error(e);
      showToast('Gagal mengunduh file laporan presensi', 'error');
    }
  };

  const exportCeremonyYearlyCSV = () => {
    try {
      const headers = ['No', 'NIP', 'Nama Pegawai', 'Unit Kerja', 'Fakultas', 'Prodi', 'Total Upacara', ...BULAN_LIST.map((b) => b.name)];
      
      const rows = filteredEmployees.map((item, idx) => {
        const p = item.pengguna || {};
        const nip = p.nip || item.kode || '';
        const nama = p.nama || `Pegawai ${nip}`;
        const unit = p.unit_kerja || p.unit || '';
        const fak = p.fakultas || '';
        const prd = p.prodi || '';

        const monthCounts = BULAN_LIST.map((b) => {
          const count = ceremonyList.filter((c) => {
            const cDate = new Date(c.tanggal);
            const isMatchingEmp = (c.nip && c.nip === nip) || (c.nidn && c.nidn === p.nidn);
            return isMatchingEmp && cDate.getFullYear() === selectedYear && (cDate.getMonth() + 1) === b.value;
          }).length;
          return count > 0 ? count : 0;
        });

        const totalUpacara = monthCounts.reduce((acc, curr) => acc + curr, 0);

        return [
          idx + 1,
          `"${nip}"`,
          `"${nama.replace(/"/g, '""')}"`,
          `"${unit.replace(/"/g, '""')}"`,
          `"${fak.replace(/"/g, '""')}"`,
          `"${prd.replace(/"/g, '""')}"`,
          totalUpacara,
          ...monthCounts,
        ].join(',');
      });

      const csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(','), ...rows].join('\n');
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement('a');
      link.setAttribute('href', encodedUri);
      link.setAttribute('download', `Laporan_Presensi_Upacara_${selectedYear}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      showToast(`File Laporan Presensi Upacara Tahun ${selectedYear} berhasil diunduh!`, 'success');
    } catch (e) {
      showToast('Gagal mengunduh file laporan upacara', 'error');
    }
  };

  const totalItems = filteredEmployees.length;
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedEmployees = filteredEmployees.slice(startIndex, startIndex + itemsPerPage);
  const datesList = getDatesList();

  const getRecordForDate = (records, dateStr) => {
    if (!records || !Array.isArray(records)) return null;
    return records.find((r) => r.tanggal === dateStr);
  };

  const handleCellClick = (emp, dateStr, record, isUpacara = false) => {
    setSelectedCell({
      emp,
      dateStr,
      record,
      isUpacara,
    });
    setIsCellModalOpen(true);
  };

  return (
    <div className="page-wrapper animate-fade-in">
      {/* Top Main Tab Navigation: Presensi vs Presensi Upacara */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', borderBottom: '1px solid var(--border-light)', paddingBottom: '12px' }}>
        <button
          onClick={() => {
            setMainReportTab('presensi');
            setSearchQuery('');
            setCurrentPage(1);
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 20px',
            borderRadius: '10px',
            border: 'none',
            backgroundColor: mainReportTab === 'presensi' ? 'var(--color-primary)' : '#f1f5f9',
            color: mainReportTab === 'presensi' ? '#ffffff' : 'var(--text-main)',
            fontWeight: 700,
            fontSize: '0.9rem',
            cursor: 'pointer',
            transition: 'all 0.15s',
          }}
        >
          <FileSpreadsheet size={18} />
          <span>Presensi</span>
        </button>

        <button
          onClick={() => {
            setMainReportTab('upacara');
            setSearchQuery('');
            setCurrentPage(1);
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 20px',
            borderRadius: '10px',
            border: 'none',
            backgroundColor: mainReportTab === 'upacara' ? 'var(--color-primary)' : '#f1f5f9',
            color: mainReportTab === 'upacara' ? '#ffffff' : 'var(--text-main)',
            fontWeight: 700,
            fontSize: '0.9rem',
            cursor: 'pointer',
            transition: 'all 0.15s',
          }}
        >
          <Award size={18} />
          <span>Presensi Upacara</span>
        </button>
      </div>

      {/* Filter Card with Periode, Fakultas, Prodi, Unit & Search */}
      <div
        className="glass-card"
        style={{
          padding: '18px 20px',
          marginBottom: '24px',
          display: 'flex',
          flexDirection: 'column',
          gap: '16px',
        }}
      >
        {/* Row 1: Primary Controls */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
            {/* Month Selector: ONLY for Presensi Reguler Tab */}
            {mainReportTab === 'presensi' && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '0.825rem', fontWeight: 700, color: 'var(--text-muted)' }}>Bulan:</span>
                <select
                  className="form-select"
                  value={selectedMonth}
                  onChange={(e) => {
                    setSelectedMonth(Number(e.target.value));
                    setCurrentPage(1);
                  }}
                  style={{ width: '130px', padding: '6px 10px', fontSize: '0.85rem' }}
                >
                  {BULAN_LIST.map((b) => (
                    <option key={b.value} value={b.value}>
                      {b.name}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Year Selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ fontSize: '0.825rem', fontWeight: 700, color: 'var(--text-muted)' }}>Tahun:</span>
              <select
                className="form-select"
                value={selectedYear}
                onChange={(e) => {
                  setSelectedYear(Number(e.target.value));
                  setCurrentPage(1);
                }}
                style={{ width: '95px', padding: '6px 10px', fontSize: '0.85rem' }}
              >
                {TAHUN_LIST.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>

            {/* Sub-Tabs: ONLY for Presensi Reguler Tab */}
            {mainReportTab === 'presensi' && (
              <div style={{ display: 'flex', backgroundColor: '#f1f5f9', borderRadius: '8px', padding: '3px' }}>
                <button
                  onClick={() => setPeriodType('calendar')}
                  style={{
                    padding: '6px 14px',
                    borderRadius: '6px',
                    border: 'none',
                    backgroundColor: periodType === 'calendar' ? 'var(--color-primary)' : 'transparent',
                    color: periodType === 'calendar' ? '#ffffff' : 'var(--text-muted)',
                    fontWeight: 700,
                    fontSize: '0.775rem',
                    cursor: 'pointer',
                    transition: 'all 0.15s',
                  }}
                >
                  Tab 01 - 31 (Bulan Penuh)
                </button>
                <button
                  onClick={() => setPeriodType('cutoff')}
                  style={{
                    padding: '6px 14px',
                    borderRadius: '6px',
                    border: 'none',
                    backgroundColor: periodType === 'cutoff' ? 'var(--color-primary)' : 'transparent',
                    color: periodType === 'cutoff' ? '#ffffff' : 'var(--text-muted)',
                    fontWeight: 700,
                    fontSize: '0.775rem',
                    cursor: 'pointer',
                    transition: 'all 0.15s',
                  }}
                >
                  Tab 16 - 15 (Cutoff Payroll)
                </button>
              </div>
            )}
          </div>

          {/* Export Button */}
          <button
            onClick={handleExportExcel}
            disabled={isExporting || loading}
            className="btn btn-primary"
            style={{ padding: '8px 16px', fontSize: '0.825rem', gap: '6px' }}
          >
            {isExporting ? (
              <>
                <RefreshCw size={15} className="animate-spin" />
                <span>Exporting ({exportProgress}%)...</span>
              </>
            ) : (
              <>
                <Download size={15} />
                <span>Export Excel</span>
              </>
            )}
          </button>
        </div>

        {/* Row 2: Master Data Filters (Fakultas, Prodi, Unit, Search) */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '12px',
            borderTop: '1px solid var(--border-light)',
            paddingTop: '14px',
          }}
        >
          {/* Fakultas Filter (from https://hrportal.unpak.ac.id/api/v2/masterdata/fakultas) */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '4px' }}>
              Fakultas
            </label>
            <select
              className="form-select"
              value={selectedFakultas}
              onChange={(e) => {
                setSelectedFakultas(e.target.value);
                setCurrentPage(1);
              }}
              style={{ width: '100%', fontSize: '0.825rem', padding: '6px 10px' }}
            >
              <option value="">Semua Fakultas</option>
              {fakultasList.map((f, i) => {
                const name = f.nama || f.nama_fakultas || f.fakultas || f.kode || `Fakultas ${i + 1}`;
                return (
                  <option key={f.id || i} value={name}>
                    {name}
                  </option>
                );
              })}
            </select>
          </div>

          {/* Prodi Filter (from https://hrportal.unpak.ac.id/api/v2/masterdata/prodi) */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '4px' }}>
              Program Studi
            </label>
            <select
              className="form-select"
              value={selectedProdi}
              onChange={(e) => {
                setSelectedProdi(e.target.value);
                setCurrentPage(1);
              }}
              style={{ width: '100%', fontSize: '0.825rem', padding: '6px 10px' }}
            >
              <option value="">Semua Program Studi</option>
              {prodiList.map((p, i) => {
                const name = p.nama || p.nama_prodi || p.prodi || p.kode || `Prodi ${i + 1}`;
                return (
                  <option key={p.id || i} value={name}>
                    {name}
                  </option>
                );
              })}
            </select>
          </div>

          {/* Unit Kerja Filter */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '4px' }}>
              Unit Kerja
            </label>
            <select
              className="form-select"
              value={selectedUnit}
              onChange={(e) => {
                setSelectedUnit(e.target.value);
                setCurrentPage(1);
              }}
              style={{ width: '100%', fontSize: '0.825rem', padding: '6px 10px' }}
            >
              <option value="">Semua Unit</option>
              {uniqueUnits.map((u, i) => (
                <option key={i} value={u}>
                  {u}
                </option>
              ))}
            </select>
          </div>

          {/* Search Input */}
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '4px' }}>
              Pencarian Pegawai
            </label>
            <div style={{ position: 'relative' }}>
              <Search
                size={15}
                color="var(--text-muted)"
                style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)' }}
              />
              <input
                type="text"
                className="form-input"
                placeholder="Cari Nama / NIP / Unit..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setCurrentPage(1);
                }}
                style={{ paddingLeft: '32px', fontSize: '0.825rem', padding: '6px 10px 6px 32px' }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: PRESENSI REGULER (BULANAN 1..31) */}
      {/* ========================================================================= */}
      {mainReportTab === 'presensi' && (
        <div className="table-container" style={{ overflowX: 'auto', maxWidth: '100%' }}>
          <table className="custom-table" style={{ fontSize: '0.78rem', minWidth: '1350px' }}>
            <thead>
              <tr>
                <th style={{ width: '45px', textAlign: 'center', position: 'sticky', left: 0, zIndex: 10, background: '#f8fafc' }}>
                  NO
                </th>
                <th style={{ minWidth: '180px', position: 'sticky', left: '45px', zIndex: 10, background: '#f8fafc' }}>
                  PEGAWAI & NIP
                </th>
                <th style={{ minWidth: '130px' }}>UNIT KERJA</th>
                <th style={{ minWidth: '160px' }}>FAKULTAS & PRODI</th>
                <th style={{ width: '80px', textAlign: 'center' }}>TOTAL HADIR</th>

                {/* Dynamic Date Headers (1..31 with Sunday / Holiday in red) */}
                {datesList.map((d) => {
                  const dayNum = d.getDate();
                  const isSunday = d.getDay() === 0;
                  const dKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
                  const isHoliday = holidays.has(dKey);

                  return (
                    <th
                      key={dKey}
                      style={{
                        width: '52px',
                        minWidth: '52px',
                        textAlign: 'center',
                        padding: '8px 2px',
                        backgroundColor: isSunday || isHoliday ? '#fee2e2' : undefined,
                        color: isSunday || isHoliday ? '#dc2626' : undefined,
                      }}
                      title={`${dKey} ${isHoliday ? '(Libur)' : ''}`}
                    >
                      <div style={{ fontWeight: 800 }}>{dayNum}</div>
                    </th>
                  );
                })}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={datesList.length + 5} style={{ textAlign: 'center', padding: '40px' }}>
                    <RefreshCw size={24} className="animate-spin" style={{ margin: '0 auto 12px', color: 'var(--color-primary)' }} />
                    <div>Memuat matriks laporan presensi pegawai...</div>
                  </td>
                </tr>
              ) : paginatedEmployees.length === 0 ? (
                <tr>
                  <td colSpan={datesList.length + 5} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    Tidak ada data pegawai pada kriteria filter terpilih ({BULAN_LIST.find((b) => b.value === selectedMonth)?.name} {selectedYear}).
                  </td>
                </tr>
              ) : (
                paginatedEmployees.map((item, index) => {
                  const globalIndex = startIndex + index + 1;
                  const p = item.pengguna || {};
                  const nip = p.nip || item.kode || '-';
                  const nama = p.nama || `Pegawai ${nip}`;
                  const unit = p.unit_kerja || p.unit || '-';
                  const fakultas = p.fakultas || '-';
                  const prodi = p.prodi || '';
                  const records = item.records || [];

                  const totalHadir = records.filter((r) => r.type === 'absen' && r.info?.masuk).length;

                  return (
                    <tr key={item.kode || index}>
                      <td
                        style={{
                          textAlign: 'center',
                          fontWeight: 600,
                          position: 'sticky',
                          left: 0,
                          zIndex: 5,
                          background: '#ffffff',
                        }}
                      >
                        {globalIndex}
                      </td>
                      <td
                        style={{
                          position: 'sticky',
                          left: '45px',
                          zIndex: 5,
                          background: '#ffffff',
                          boxShadow: '2px 0 4px rgba(0,0,0,0.02)',
                        }}
                      >
                        <div style={{ fontWeight: 800, color: 'var(--text-main)' }}>{nama}</div>
                        <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>NIP: {nip}</div>
                      </td>
                      <td>
                        <div style={{ fontSize: '0.78rem', color: '#475569', maxWidth: '130px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {unit}
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-main)', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {fakultas}
                        </div>
                        {prodi && (
                          <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '1px', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            Prodi: {prodi}
                          </div>
                        )}
                      </td>
                      <td style={{ textAlign: 'center', fontWeight: 800, color: 'var(--color-primary)' }}>
                        {totalHadir}
                      </td>

                      {/* Day Cells with Check-in Time */}
                      {datesList.map((d) => {
                        const dKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
                        const isSunday = d.getDay() === 0;
                        const isHoliday = holidays.has(dKey);

                        let bg = 'transparent';
                        let text = '-';
                        let textColor = '#94a3b8';
                        let cellRecord = null;
                        let isHadir = false;

                        if (isSunday || isHoliday) {
                          bg = '#fef2f2';
                          text = 'L';
                          textColor = '#ef4444';
                        }

                        const rec = getRecordForDate(records, dKey);
                        cellRecord = rec;
                        if (rec) {
                          if (rec.type === 'absen') {
                            isHadir = true;
                            bg = '#ecfdf5';
                            text = formatJamMasuk(rec.info?.masuk) || 'Hadir';
                            textColor = '#047857';
                          } else if (rec.type === 'izin') {
                            bg = '#eff6ff';
                            text = 'I';
                            textColor = '#3b82f6';
                          } else if (rec.type === 'cuti') {
                            bg = '#f5f3ff';
                            text = 'C';
                            textColor = '#8b5cf6';
                          } else if (rec.type === 'sppd') {
                            bg = '#fffbeb';
                            text = 'S';
                            textColor = '#f59e0b';
                          }
                        }

                        return (
                          <td
                            key={dKey}
                            onClick={() => handleCellClick(p, dKey, cellRecord, false)}
                            style={{
                              textAlign: 'center',
                              backgroundColor: bg,
                              color: textColor,
                              fontWeight: isHadir ? 800 : 700,
                              fontSize: isHadir ? '0.72rem' : '0.78rem',
                              padding: '6px 2px',
                              cursor: 'pointer',
                              transition: 'all 0.1s',
                            }}
                            title={`Klik untuk detail ${dKey} ${isHadir ? `(Jam Masuk: ${text})` : ''}`}
                          >
                            {text}
                          </td>
                        );
                      })}
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>

          {/* Pagination */}
          {!loading && totalItems > 0 && (
            <Pagination
              currentPage={currentPage}
              totalItems={totalItems}
              itemsPerPage={itemsPerPage}
              onPageChange={(p) => setCurrentPage(p)}
              onItemsPerPageChange={(limit) => {
                setItemsPerPage(limit);
                setCurrentPage(1);
              }}
            />
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: PRESENSI UPACARA (TAHUNAN 12 BULAN DENGAN JAM MASUK) */}
      {/* ========================================================================= */}
      {mainReportTab === 'upacara' && (
        <div className="table-container" style={{ overflowX: 'auto', maxWidth: '100%' }}>
          <table className="custom-table" style={{ fontSize: '0.8rem', minWidth: '1150px' }}>
            <thead>
              <tr>
                <th style={{ width: '45px', textAlign: 'center', position: 'sticky', left: 0, zIndex: 10, background: '#f8fafc' }}>
                  NO
                </th>
                <th style={{ minWidth: '180px', position: 'sticky', left: '45px', zIndex: 10, background: '#f8fafc' }}>
                  PEGAWAI & NIP
                </th>
                <th style={{ minWidth: '130px' }}>UNIT KERJA</th>
                <th style={{ minWidth: '160px' }}>FAKULTAS & PRODI</th>
                <th style={{ width: '85px', textAlign: 'center', backgroundColor: '#faf5ff', color: 'var(--color-primary)' }}>
                  TOTAL HADIR
                </th>

                {/* 12 Bulan Headers */}
                {BULAN_LIST.map((b) => (
                  <th key={b.value} style={{ width: '60px', textAlign: 'center' }}>
                    <div style={{ fontWeight: 800 }}>{b.value}</div>
                    <div style={{ fontSize: '0.68rem', fontWeight: 500, color: 'var(--text-muted)' }}>{b.short}</div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="17" style={{ textAlign: 'center', padding: '40px' }}>
                    <RefreshCw size={24} className="animate-spin" style={{ margin: '0 auto 12px', color: 'var(--color-primary)' }} />
                    <div>Memuat matriks presensi upacara tahun {selectedYear}...</div>
                  </td>
                </tr>
              ) : paginatedEmployees.length === 0 ? (
                <tr>
                  <td colSpan="17" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    Tidak ada data pegawai pada kriteria filter tahun {selectedYear}.
                  </td>
                </tr>
              ) : (
                paginatedEmployees.map((item, index) => {
                  const globalIndex = startIndex + index + 1;
                  const p = item.pengguna || {};
                  const nip = p.nip || item.kode || '-';
                  const nama = p.nama || `Pegawai ${nip}`;
                  const unit = p.unit_kerja || p.unit || '-';
                  const fakultas = p.fakultas || '-';
                  const prodi = p.prodi || '';

                  // Ceremony attendances for this employee in selectedYear
                  const empCeremonies = ceremonyList.filter((c) => {
                    const cDate = new Date(c.tanggal);
                    const isMatchingEmp = (c.nip && c.nip === nip) || (c.nidn && c.nidn === p.nidn);
                    return isMatchingEmp && cDate.getFullYear() === selectedYear;
                  });

                  const totalHadir = empCeremonies.length;

                  return (
                    <tr key={item.kode || index}>
                      <td
                        style={{
                          textAlign: 'center',
                          fontWeight: 600,
                          position: 'sticky',
                          left: 0,
                          zIndex: 5,
                          background: '#ffffff',
                        }}
                      >
                        {globalIndex}
                      </td>
                      <td
                        style={{
                          position: 'sticky',
                          left: '45px',
                          zIndex: 5,
                          background: '#ffffff',
                          boxShadow: '2px 0 4px rgba(0,0,0,0.02)',
                        }}
                      >
                        <div style={{ fontWeight: 800, color: 'var(--text-main)' }}>{nama}</div>
                        <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>NIP: {nip}</div>
                      </td>
                      <td>
                        <div style={{ fontSize: '0.78rem', color: '#475569' }}>{unit}</div>
                      </td>
                      <td>
                        <div style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-main)' }}>
                          {fakultas}
                        </div>
                        {prodi && (
                          <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '1px' }}>
                            Prodi: {prodi}
                          </div>
                        )}
                      </td>
                      <td style={{ textAlign: 'center', fontWeight: 800, color: 'var(--color-primary)', backgroundColor: '#faf5ff' }}>
                        <span
                          style={{
                            background: totalHadir > 0 ? 'var(--color-primary-100)' : '#f1f5f9',
                            color: totalHadir > 0 ? 'var(--color-primary)' : 'var(--text-muted)',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '0.8rem',
                          }}
                        >
                          {totalHadir}
                        </span>
                      </td>

                      {/* 12 Bulan Cells with Jam Masuk Upacara */}
                      {BULAN_LIST.map((b) => {
                        const monthCeremonies = empCeremonies.filter((c) => {
                          const cDate = new Date(c.tanggal);
                          return (cDate.getMonth() + 1) === b.value;
                        });

                        const isAttended = monthCeremonies.length > 0;
                        const firstRecord = monthCeremonies[0];
                        const displayTime = isAttended ? (formatJamMasuk(firstRecord.created_at || firstRecord.tanggal) || '07:00') : '-';

                        return (
                          <td
                            key={b.value}
                            onClick={() => isAttended && handleCellClick(p, firstRecord.tanggal, firstRecord, true)}
                            style={{
                              textAlign: 'center',
                              fontWeight: isAttended ? 800 : 400,
                              fontSize: isAttended ? '0.75rem' : '0.8rem',
                              color: isAttended ? '#047857' : '#cbd5e1',
                              backgroundColor: isAttended ? '#ecfdf5' : 'transparent',
                              cursor: isAttended ? 'pointer' : 'default',
                              padding: '6px 2px',
                            }}
                            title={isAttended ? `Hadir Upacara: ${formatTanggalIndo(firstRecord.tanggal)} (Jam: ${displayTime})` : `Bulan ${b.name}: Tidak ada upacara`}
                          >
                            {displayTime}
                          </td>
                        );
                      })}
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>

          {/* Pagination */}
          {!loading && totalItems > 0 && (
            <Pagination
              currentPage={currentPage}
              totalItems={totalItems}
              itemsPerPage={itemsPerPage}
              onPageChange={(p) => setCurrentPage(p)}
              onItemsPerPageChange={(limit) => {
                setItemsPerPage(limit);
                setCurrentPage(1);
              }}
            />
          )}
        </div>
      )}

      {/* Cell Detail Modal */}
      <Modal
        isOpen={isCellModalOpen}
        onClose={() => setIsCellModalOpen(false)}
        title={selectedCell?.isUpacara ? 'Detail Presensi Upacara' : 'Detail Presensi Pegawai'}
        maxWidth="500px"
      >
        {selectedCell && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ padding: '14px', backgroundColor: '#f8fafc', borderRadius: '10px' }}>
              <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{selectedCell.emp?.nama || selectedCell.emp?.nip}</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                NIP: {selectedCell.emp?.nip || '-'} • Unit: {selectedCell.emp?.unit_kerja || selectedCell.emp?.unit || '-'}
              </div>
              <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px' }}>
                {[selectedCell.emp?.fakultas, selectedCell.emp?.prodi].filter(Boolean).join(' • ') || 'Universitas Pakuan'}
              </div>
              <div style={{ fontSize: '0.825rem', fontWeight: 600, color: 'var(--color-primary)', marginTop: '6px' }}>
                📅 {formatTanggalIndo(selectedCell.dateStr)}
              </div>
            </div>

            {selectedCell.record ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', background: '#f1f5f9', borderRadius: '6px' }}>
                  <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Status Kehadiran:</span>
                  <strong style={{ textTransform: 'uppercase', fontSize: '0.85rem', color: '#047857' }}>
                    {selectedCell.isUpacara ? 'HADIR UPACARA' : selectedCell.record.type}
                  </strong>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', background: '#ecfdf5', borderRadius: '6px' }}>
                  <span style={{ fontSize: '0.8rem', color: '#047857' }}>Jam Masuk:</span>
                  <strong style={{ fontSize: '0.85rem', color: '#065f46' }}>
                    {selectedCell.isUpacara 
                      ? (formatJamMasuk(selectedCell.record.created_at || selectedCell.record.tanggal) || '07:00 WIB')
                      : (selectedCell.record.info?.masuk || '-')}
                  </strong>
                </div>

                {!selectedCell.isUpacara && selectedCell.record.info?.keluar && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 12px', background: '#eff6ff', borderRadius: '6px' }}>
                    <span style={{ fontSize: '0.8rem', color: '#1d4ed8' }}>Jam Keluar:</span>
                    <strong style={{ fontSize: '0.85rem', color: '#1e40af' }}>{selectedCell.record.info.keluar}</strong>
                  </div>
                )}
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: '16px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                {holidays.has(selectedCell.dateStr) ? 'Hari Libur Kalender / Universitas' : (selectedCell.isUpacara ? 'Tidak ada catatan presensi upacara pada tanggal ini.' : 'Tidak ada catatan presensi / Alpha pada tanggal ini.')}
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
};
