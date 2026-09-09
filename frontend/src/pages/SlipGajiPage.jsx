import React, { useState, useEffect } from 'react';
import { Printer, RefreshCw } from 'lucide-react';
import { apiClient } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';

export const defaultFormatRupiah = (val) => {
  if (val === undefined || val === null) return '0';
  const num = typeof val === 'number' ? val : (parseFloat(val) || 0);
  return new Intl.NumberFormat('id-ID').format(num);
};

export const toNum = (val) => Number(val) || 0;

export const SlipGajiPegawai = ({
  data = {},
  formatRupiah = defaultFormatRupiah
}) => {
  const bpjs = toNum(data.bpjs);
  const astek = toNum(data.astekP) + toNum(data.astekY) + bpjs + (bpjs > 0 ? bpjs / 2 : 0);
  const dlpk = toNum(data.dplkP) + toNum(data.dplkY);

  const astek_dlpk = toNum(data.gajikotor) > 0
    ? toNum(data.gajikotor) - toNum(data.gajibersih)
    : 0;

  return (
    <div style={{ fontSize: '12px', fontFamily: 'Arial, sans-serif', background: '#fff', padding: '16px', border: '1px solid #000' }}>
      <table
        width="355px"
        style={{
          fontWeight: 'bold',
          borderCollapse: 'collapse',
          border: '1px solid #000',
          marginBottom: '3px'
        }}
      >
        <tbody>
          <tr align="center">
            <td style={{ paddingTop: '5px' }}>
              <h4 style={{ fontWeight: 'bold', margin: '0px', fontSize: '14px' }}>
                UNIT KERJA/FAKULTAS {data.prodi ? data.prodi : 'REKTORAT'}
              </h4>
              <h4 style={{ fontWeight: 'bold', margin: '0px', fontSize: '14px' }}>
                UNIVERSITAS PAKUAN
              </h4>
              <h3 style={{ fontWeight: 'bold', margin: '0px', fontSize: '16px' }}>
                <u>GAJI dan TUNJANGAN</u>
              </h3>
              <h4 style={{ fontWeight: 'bold', margin: '3px', fontSize: '14px' }}>
                Bulan/Tahun : {data.bulan}/{data.tahun}
              </h4>
            </td>
          </tr>
        </tbody>
      </table>

      <table
        width="355px"
        cellPadding="0"
        cellSpacing="0"
        style={{
          borderCollapse: 'collapse',
          border: '1px solid #000',
          fontSize: '12px'
        }}
      >
        <tbody>
          <tr align="center">
            <td align="left" style={{ width: '100px', verticalAlign: 'top' }}>
              &nbsp;<b>No. Urut</b>
            </td>
            <td align="left" colSpan={5}>
              : {data.no_mesin || data.no_urut || ''}
              <label style={{ margin: 0, float: 'right' }}>Hari&nbsp;</label>
            </td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Nama</b>
            </td>
            <td align="left" colSpan={5}>
              : {data.nama || ''}
            </td>
          </tr>

          {/* Gaji Pokok */}
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>Gaji Pokok</b>
            </td>
            <td width="20px"></td>
            <td width="110px" align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gaji_pokok ?? data.gajiPokok)}&nbsp;
              </label>
            </td>
            <td width="10px"></td>
            <td width="110px" align="left" style={{ paddingTop: '10px' }}></td>
            <td></td>
          </tr>

          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Suami/istri</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tkeluarga ?? data.suami_istri)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Anak</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tanak ?? data.anak)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Pangan</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tpangan ?? data.pangan)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Struktural</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tstruktural ?? data.struktural)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Fungsional</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tfungsional ?? data.fungsional)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Transpot</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.transpot ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Khusus</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tkhusus ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Astek/DPLK</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.astekY ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>BPJS</b>
            </td>
            <td style={{ borderBottom: '1px solid #000' }}></td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.bpjs)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Jumlah Pendapatan</b>
            </td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gajikotor ?? 0)}
              </label>
            </td>
            <td></td>
          </tr>

          {/* Potongan */}
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>Astek</b>
            </td>
            <td></td>
            <td align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(astek)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>DPLK</b>
            </td>
            <td></td>
            <td align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(dlpk)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Koperasi</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pkoperasi ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Yayasan</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pyayasan ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Zakat 2.5%</b>
            </td>
            <td style={{ borderBottom: '1px solid #000' }}></td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pzakat ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Jumlah Potongan</b>
            </td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(astek_dlpk)}
              </label>
            </td>
            <td></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Pendapatan Bersih</b>
            </td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gajibersih ?? 0)}
              </label>
            </td>
            <td></td>
          </tr>
        </tbody>
      </table>

      <table
        width="355px"
        cellPadding="0"
        cellSpacing="0"
        style={{ padding: '0px 30px', fontSize: '12px', marginTop: '4px' }}
      >
        <tbody>
          <tr align="center">
            <td align="left" style={{ width: '45%', verticalAlign: 'top' }}>&nbsp;</td>
            <td align="center" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Bogor, {data.bulan} {data.tahun}</b>
            </td>
          </tr>
          <tr align="center">
            <td align="center" style={{ verticalAlign: 'top' }}>&nbsp;<b>Yang Menerima,</b></td>
            <td align="center" style={{ verticalAlign: 'top' }}>&nbsp;<b>Yang Menyerahkan,</b></td>
          </tr>
          <tr align="center">
            <td align="center" style={{ verticalAlign: 'top' }}>
              <br /><br />
              <b>({data.nama || ''})</b>
            </td>
            <td align="center" style={{ verticalAlign: 'top' }}></td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export const SlipGajiDosen = ({
  data = {},
  formatRupiah = defaultFormatRupiah
}) => {
  const bpjs = toNum(data.bpjs);
  const astek = toNum(data.astekP) + toNum(data.astekY) + bpjs + (bpjs > 0 ? bpjs / 2 : 0);
  const dlpk = toNum(data.dplkP) + toNum(data.dplkY);

  const astek_dlpk = toNum(data.gajikotor) > 0
    ? toNum(data.gajikotor) - toNum(data.gajibersih)
    : 0;

  return (
    <div style={{ fontSize: '12px', fontFamily: 'Arial, sans-serif', background: '#fff', padding: '16px', border: '1px solid #000' }}>
      <table
        width="355px"
        style={{
          fontWeight: 'bold',
          borderCollapse: 'collapse',
          border: '1px solid #000',
          marginBottom: '3px'
        }}
      >
        <tbody>
          <tr align="center">
            <td style={{ paddingTop: '5px' }}>
              <h4 style={{ fontWeight: 'bold', margin: '0px', fontSize: '14px' }}>
                UNIT KERJA/FAKULTAS {data.prodi ? data.prodi : ''}
              </h4>
              <h4 style={{ fontWeight: 'bold', margin: '0px', fontSize: '14px' }}>
                UNIVERSITAS PAKUAN
              </h4>
              <h3 style={{ fontWeight: 'bold', margin: '0px', fontSize: '16px' }}>
                <u>GAJI dan TUNJANGAN</u>
              </h3>
              <h4 style={{ fontWeight: 'bold', margin: '3px', fontSize: '14px' }}>
                Bulan/Tahun : {data.bulan}/{data.tahun}
              </h4>
            </td>
          </tr>
        </tbody>
      </table>

      <table
        width="355px"
        cellPadding="0"
        cellSpacing="0"
        style={{
          borderCollapse: 'collapse',
          border: '1px solid #000',
          fontSize: '12px'
        }}
      >
        <tbody>
          <tr align="center">
            <td align="left" style={{ width: '100px', verticalAlign: 'top' }}>
              &nbsp;<b>No. Urut</b>
            </td>
            <td align="left" colSpan={5}>
              : {data.no_mesin || data.no_urut || ''}
              <label style={{ margin: 0, float: 'right' }}>Hari&nbsp;</label>
            </td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Nama</b>
            </td>
            <td align="left" colSpan={5}>
              : {data.nama || ''}
            </td>
          </tr>

          {/* Gaji Pokok */}
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>Gaji Pokok</b>
            </td>
            <td width="20px"></td>
            <td width="110px" align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gaji_pokok ?? data.gajiPokok)}&nbsp;
              </label>
            </td>
            <td width="10px"></td>
            <td width="110px" align="left" style={{ paddingTop: '10px' }}></td>
            <td></td>
          </tr>

          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Suami/istri</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tkeluarga ?? data.suami_istri)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Anak</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tanak ?? data.anak)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Pangan</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tpangan ?? data.pangan)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Struktural</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tstruktural ?? data.struktural)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Fungsional</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tfungsional ?? data.fungsional)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          {/* Mengajar Breakdown */}
          <tr align="center">
            <td align="left" colSpan={6} style={{ fontWeight: 'bold', paddingTop: '4px' }}>
              &nbsp;Mengajar :
            </td>
          </tr>
          <tr align="center">
            <td align="left">&nbsp;&nbsp;-S1</td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.mengajar ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left">&nbsp;&nbsp;-S1-NonReg</td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.nonregular ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left">&nbsp;&nbsp;-Vokasi</td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.D3regular ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left">&nbsp;&nbsp;-Vokasi-NonReg</td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.D3nonregular ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left">&nbsp;&nbsp;-Pasca</td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pascasarjana ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Transpot</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.transpot ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Khusus</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.tkhusus ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Astek/DPLK</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.astekY ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>BPJS</b>
            </td>
            <td style={{ borderBottom: '1px solid #000' }}></td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.bpjs)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Jumlah Pendapatan</b>
            </td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gajikotor ?? 0)}
              </label>
            </td>
            <td></td>
          </tr>

          {/* Potongan */}
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>Astek</b>
            </td>
            <td></td>
            <td align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(astek)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top', paddingTop: '10px' }}>
              &nbsp;<b>DPLK</b>
            </td>
            <td></td>
            <td align="left" style={{ paddingTop: '10px' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(dlpk)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Koperasi</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pkoperasi ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Yayasan</b>
            </td>
            <td></td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pyayasan ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>
          <tr align="center">
            <td align="left" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Zakat 2.5%</b>
            </td>
            <td style={{ borderBottom: '1px solid #000' }}></td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.pzakat ?? 0)}&nbsp;
              </label>
            </td>
            <td colSpan={3}></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Jumlah Potongan</b>
            </td>
            <td align="left" style={{ borderBottom: '1px solid #000' }}>
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(astek_dlpk)}
              </label>
            </td>
            <td></td>
          </tr>

          <tr align="center">
            <td align="left" colSpan={4} style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Pendapatan Bersih</b>
            </td>
            <td align="left">
              Rp.&nbsp;
              <label style={{ margin: 0, float: 'right', fontWeight: 'normal' }}>
                {formatRupiah(data.gajibersih ?? 0)}
              </label>
            </td>
            <td></td>
          </tr>
        </tbody>
      </table>

      <table
        width="355px"
        cellPadding="0"
        cellSpacing="0"
        style={{ padding: '0px 30px', fontSize: '12px', marginTop: '4px' }}
      >
        <tbody>
          <tr align="center">
            <td align="left" style={{ width: '45%', verticalAlign: 'top' }}>&nbsp;</td>
            <td align="center" style={{ verticalAlign: 'top' }}>
              &nbsp;<b>Bogor, {data.bulan} {data.tahun}</b>
            </td>
          </tr>
          <tr align="center">
            <td align="center" style={{ verticalAlign: 'top' }}>&nbsp;<b>Yang Menerima,</b></td>
            <td align="center" style={{ verticalAlign: 'top' }}>&nbsp;<b>Yang Menyerahkan,</b></td>
          </tr>
          <tr align="center">
            <td align="center" style={{ verticalAlign: 'top' }}>
              <br /><br />
              <b>({data.nama || ''})</b>
            </td>
            <td align="center" style={{ verticalAlign: 'top' }}></td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export const SlipGajiAdapter = ({
  apiResponse,
  tipe = '',
  formatRupiah = defaultFormatRupiah
}) => {
  const payload = apiResponse?.data ?? apiResponse ?? {};

  console.log(payload, tipe)
  if (tipe === 'dosen') {
    return <SlipGajiDosen data={payload} formatRupiah={formatRupiah} />;
  }

  return <SlipGajiPegawai data={payload} formatRupiah={formatRupiah} />;
};

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

  const yearsList = Array.from({ length: currentYearNum - 2000 + 1 }, (_, i) => currentYearNum - i);

  const fetchPayroll = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/api/v2/payroll?bulan=${selectedMonth}&tahun=${selectedYear}`);
      let data = null;
      if (res && res.data) {
        data = Array.isArray(res.data) ? res.data[0] : res.data;
      } else if (res && typeof res === 'object') {
        data = res;
      }

      if (data) {
        setPayrollData(data);
      }
    } catch (err) {
      console.warn('Backend /api/v2/payroll note:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayroll();
  }, [selectedMonth, selectedYear]);

  const selectedMonthName = monthNames.find((m) => m.value === selectedMonth)?.label || 'Januari';

  const handlePrint = () => {
    window.print();
    if (showToast) showToast('Mencetak Slip Gaji Resmi UNPAK...', 'info');
  };

  const payloadWithFallback = {
    bulan: selectedMonthName,
    tahun: selectedYear,
    nama: user?.name,
    ...payrollData
  };

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

      {/* Slip Gaji Output Paper Document */}
      <div id="official-slip-gaji">
        <SlipGajiAdapter apiResponse={payloadWithFallback} tipe={payloadWithFallback.status=="DOSEN"? "dosen":"pegawai"} />
      </div>
    </div>
  );
};

export default SlipGajiPage;
