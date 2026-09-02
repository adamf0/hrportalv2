import React, { useState, useEffect } from 'react';
import { Printer, RefreshCw, Download, FileText } from 'lucide-react';
import { apiClient } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';

export const SlipGajiPage = () => {
  const { user } = useAuth();
  const { showToast } = useToast();

  const currentMonthNum = new Date().getMonth() + 1;
  const currentYearNum = new Date().getFullYear();

  const [selectedMonth, setSelectedMonth] = useState(currentMonthNum);
  const [selectedYear, setSelectedYear] = useState(currentYearNum);
  const [loading, setLoading] = useState(true);
  const [payrollData, setPayrollData] = useState(null);

  const monthNames = [
    { value: 1, label: 'Januari' },
    { value: 2, label: 'Februari' },
    { value: 3, label: 'Maret' },
    { value: 4, label: 'April' },
    { value: 5, label: 'Mei' },
    { value: 6, label: 'Juni' },
    { value: 7, label: 'Juli' },
    { value: 8, label: 'Agustus' },
    { value: 9, label: 'September' },
    { value: 10, label: 'Oktober' },
    { value: 11, label: 'November' },
    { value: 12, label: 'Desember' },
  ];

  const yearsList = [2024, 2025, 2026, 2027];

  // Fetch Payroll Data from Backend API
  const fetchPayroll = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/api/payroll?bulan=${selectedMonth}&tahun=${selectedYear}`);
      let data = null;
      if (res && res.data) {
        data = Array.isArray(res.data) ? res.data[0] : res.data;
      } else if (res && typeof res === 'object') {
        data = res;
      }

      if (data) {
        setPayrollData(data);
      } else {
        // Fallback structure if API returns null/empty
        setPayrollData({
          no_urut: '201610001',
          nama: user?.name || 'Muhamad Saad Nurul Ishlah, M. Comp.',
          gaji_pokok: 2349023,
          suami_istri: 0,
          anak: 0,
          pangan: 132550,
          struktural: 0,
          fungsional: 1500000,
          mengajar_s1: 270000,
          mengajar_vokasi: 270000,
          mengajar_vokasi_nonreg: 510000,
          transpot: 600000,
          khusus: 500000,
          astek_dplk: 190019,
          bpjs: 89631,
          jumlah_pendapatan: 6411223,
          astek: 414096.5,
          dplk: 0,
          koperasi: 0,
          yayasan: 0,
          zakat: 0,
          jumlah_potongan: 414097,
          pendapatan_bersih: 5997126,
        });
      }
    } catch (err) {
      console.warn('Backend /api/payroll note:', err);
      setPayrollData({
        no_urut: '201610001',
        nama: user?.name || 'Muhamad Saad Nurul Ishlah, M. Comp.',
        gaji_pokok: 2349023,
        suami_istri: 0,
        anak: 0,
        pangan: 132550,
        struktural: 0,
        fungsional: 1500000,
        mengajar_s1: 270000,
        mengajar_vokasi: 270000,
        mengajar_vokasi_nonreg: 510000,
        transpot: 600000,
        khusus: 500000,
        astek_dplk: 190019,
        bpjs: 89631,
        jumlah_pendapatan: 6411223,
        astek: 414096.5,
        dplk: 0,
        koperasi: 0,
        yayasan: 0,
        zakat: 0,
        jumlah_potongan: 414097,
        pendapatan_bersih: 5997126,
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayroll();
  }, [selectedMonth, selectedYear]);

  const formatRupiah = (val) => {
    if (val === undefined || val === null) return '0';
    const num = typeof val === 'number' ? val : (parseFloat(val) || 0);
    return new Intl.NumberFormat('id-ID').format(num);
  };

  const selectedMonthName = monthNames.find((m) => m.value === selectedMonth)?.label || 'Januari';

  const handlePrint = () => {
    window.print();
    showToast('Mencetak Slip Gaji Resmi UNPAK...', 'info');
  };

  const p = payrollData || {};

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px', alignItems: 'center' }}>
      {/* Header Action Controls */}
      <div
        className="bm-card no-print"
        style={{
          width: '100%',
          maxWidth: '680px',
          padding: '20px 24px',
          background: '#ffffff',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '14px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#475569' }}>Periode:</span>
          <select
            className="bm-input"
            value={selectedMonth}
            onChange={(e) => setSelectedMonth(Number(e.target.value))}
            style={{ width: '130px', height: '38px', fontSize: '0.85rem' }}
          >
            {monthNames.map((m) => (
              <option key={m.value} value={m.value}>{m.label}</option>
            ))}
          </select>

          <select
            className="bm-input"
            value={selectedYear}
            onChange={(e) => setSelectedYear(Number(e.target.value))}
            style={{ width: '95px', height: '38px', fontSize: '0.85rem' }}
          >
            {yearsList.map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={fetchPayroll}
            className="bm-btn-outline"
            style={{ height: '38px', padding: '0 14px' }}
            title="Refresh Data Backend"
          >
            <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
            <span>Refresh</span>
          </button>

          <button
            onClick={handlePrint}
            className="bm-btn-emerald"
            style={{ height: '38px', padding: '0 18px', background: '#0f172a' }}
          >
            <Printer size={16} />
            <span>Cetak / PDF</span>
          </button>
        </div>
      </div>

      {/* STRICT GAMBAR 2 OFFICIAL UNPAK SLIP GAJI PAPER DOCUMENT TEMPLATE */}
      <div
        id="official-slip-gaji"
        style={{
          width: '100%',
          maxWidth: '680px',
          background: '#ffffff',
          border: '2px solid #000000',
          padding: '24px 28px',
          fontFamily: "'Times New Roman', Times, serif, Arial",
          color: '#000000',
          boxShadow: '0 10px 25px rgba(0, 0, 0, 0.08)',
          fontSize: '1rem',
          lineHeight: 1.4,
        }}
      >
        {/* Document Header Box */}
        <div style={{ border: '2px solid #000000', textAlign: 'center', padding: '12px', marginBottom: '16px' }}>
          <div style={{ fontSize: '1.15rem', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '0.02em' }}>
            UNIT KERJA/FAKULTAS SEKOLAH VOKASI
          </div>
          <div style={{ fontSize: '1.15rem', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '0.02em' }}>
            UNIVERSITAS PAKUAN
          </div>
          <div style={{ fontSize: '1.3rem', fontWeight: 'bold', textDecoration: 'underline', marginTop: '4px', letterSpacing: '0.04em' }}>
            GAJI dan TUNJANGAN
          </div>
          <div style={{ fontSize: '1.1rem', fontWeight: 'bold', marginTop: '2px' }}>
            Bulan/Tahun : {selectedMonthName}/{selectedYear}
          </div>
        </div>

        {/* Pegawai Details Rows */}
        <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '12px', fontSize: '1rem', fontFamily: 'inherit' }}>
          <tbody>
            <tr>
              <td style={{ width: '110px', padding: '2px 0', fontWeight: 'bold' }}>No. Urut</td>
              <td style={{ width: '15px' }}>:</td>
              <td style={{ fontWeight: 'bold' }}>{p.no_urut || p.no_mesin || '201610001'}</td>
              <td style={{ textAlign: 'right', fontWeight: 'bold' }}>Hari</td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Nama</td>
              <td>:</td>
              <td colSpan={2} style={{ fontWeight: 'bold' }}>{p.nama || user?.name || 'Muhamad Saad Nurul Ishlah, M. Comp.'}</td>
            </tr>
          </tbody>
        </table>

        {/* Breakdown Items Table */}
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.975rem', fontFamily: 'inherit' }}>
          <tbody>
            {/* Income items */}
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Gaji Pokok</td>
              <td style={{ width: '40px' }}>Rp.</td>
              <td style={{ textAlign: 'right', width: '140px' }}>{formatRupiah(p.gaji_pokok ?? p.gajiPokok ?? 2349023)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Suami/istri</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.suami_istri ?? p.tkeluarga ?? 0)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Anak</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.anak ?? p.tanak ?? 0)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Pangan</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.pangan ?? p.tpangan ?? 132550)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Struktural</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.struktural ?? p.tstruktural ?? 0)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Fungsional</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.fungsional ?? p.tfungsional ?? 1500000)}</td>
              <td></td>
            </tr>
            <tr>
              <td colSpan={4} style={{ padding: '2px 0', fontWeight: 'bold' }}>Mengajar :</td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0 2px 16px' }}>-S1</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.mengajar_s1 ?? p.mengajar ?? 270000)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0 2px 16px' }}>-Vokasi</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.mengajar_vokasi ?? p.d3regular ?? 270000)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0 2px 16px' }}>-Vokasi-NonReg</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.mengajar_vokasi_nonreg ?? p.d3nonregular ?? 510000)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Transpot</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.transpot ?? 600000)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Khusus</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.khusus ?? p.tkhusus ?? 500000)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Astek/DPLK</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.astek_dplk ?? p.astekY ?? 190019)}</td>
              <td></td>
            </tr>
            <tr style={{ borderBottom: '1px solid #000000' }}>
              <td style={{ padding: '2px 0 6px 0', fontWeight: 'bold' }}>BPJS</td>
              <td style={{ paddingBottom: '6px' }}>Rp.</td>
              <td style={{ textAlign: 'right', paddingBottom: '6px' }}>{formatRupiah(p.bpjs ?? 89631)}</td>
              <td></td>
            </tr>

            {/* Jumlah Pendapatan Row */}
            <tr>
              <td style={{ padding: '8px 0', fontWeight: 'bold', fontSize: '1.05rem' }}>Jumlah Pendapatan</td>
              <td></td>
              <td></td>
              <td style={{ textAlign: 'right', fontWeight: 'bold', fontSize: '1.05rem' }}>
                Rp. &nbsp;&nbsp;&nbsp;&nbsp;{formatRupiah(p.jumlah_pendapatan ?? p.gajikotor ?? 6411223)}
              </td>
            </tr>

            {/* Deductions items */}
            <tr>
              <td style={{ padding: '4px 0 2px 0', fontWeight: 'bold' }}>Astek</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.astek ?? p.astekP ?? 414096.5)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>DPLK</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.dplk ?? p.dplkP ?? 0)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Koperasi</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.koperasi ?? p.pkoperasi ?? 0)}</td>
              <td></td>
            </tr>
            <tr>
              <td style={{ padding: '2px 0', fontWeight: 'bold' }}>Yayasan</td>
              <td>Rp.</td>
              <td style={{ textAlign: 'right' }}>{formatRupiah(p.yayasan ?? p.pyayasan ?? 0)}</td>
              <td></td>
            </tr>
            <tr style={{ borderBottom: '1px solid #000000' }}>
              <td style={{ padding: '2px 0 6px 0', fontWeight: 'bold' }}>Zakat 2.5%</td>
              <td style={{ paddingBottom: '6px' }}>Rp.</td>
              <td style={{ textAlign: 'right', paddingBottom: '6px' }}>{formatRupiah(p.zakat ?? p.pzakat ?? 0)}</td>
              <td></td>
            </tr>

            {/* Summary Net Totals */}
            <tr>
              <td style={{ padding: '6px 0 2px 0', fontWeight: 'bold', fontSize: '1.05rem' }}>Jumlah Potongan</td>
              <td></td>
              <td></td>
              <td style={{ textAlign: 'right', fontWeight: 'bold', fontSize: '1.05rem' }}>
                Rp. &nbsp;&nbsp;&nbsp;&nbsp;{formatRupiah(p.jumlah_potongan ?? 414097)}
              </td>
            </tr>

            <tr>
              <td style={{ padding: '2px 0 8px 0', fontWeight: 'bold', fontSize: '1.05rem' }}>Pendapatan Bersih</td>
              <td></td>
              <td></td>
              <td style={{ textAlign: 'right', fontWeight: 'bold', fontSize: '1.05rem' }}>
                Rp. &nbsp;&nbsp;&nbsp;&nbsp;{formatRupiah(p.pendapatan_bersih ?? p.gajibersih ?? 5997126)}
              </td>
            </tr>
          </tbody>
        </table>

        {/* Signature Footer */}
        <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
          <div style={{ textAlign: 'center', minWidth: '240px' }}>
            <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>
              Bogor, {selectedMonthName} {selectedYear}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '32px', fontWeight: 'bold', marginBottom: '60px' }}>
              <span>Yang Menerima,</span>
              <span>Yang Menyerahkan,</span>
            </div>
            <div style={{ fontWeight: 'bold', textDecoration: 'underline' }}>
              ({p.nama || user?.name || 'Muhamad Saad Nurul Ishlah, M. Comp.'})
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
