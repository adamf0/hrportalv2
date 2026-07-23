# Catatan Perubahan Database (`note_update.md`)

Dokumen ini berisi perbandingan struktur database aktif `unpak_hrportal` dengan berkas dump SQL original [`dump-unpak_hrportal-update.sql`](file:///Users/adamf/Documents/flutter_project/hrportalv2/dump-unpak_hrportal-update.sql).

---

## 1. 🆕 Tabel Baru yang Ditambahkan (*New Tables*)

Tabel-tabel baru yang dibuat dan ditambahkan untuk mendukung fitur-fitur baru aplikasi HRPortal v2:

1. **`notifications`**
   - **Fungsi**: Tabel kontrol dan histori notifikasi FCM push (HTTP v1 API), audit trail status pengiriman (`done`, `pending`, `failed`, `circuit_broken`), penanganan *circuit breaker*, dan *in-app notification inbox*.
   - **Struktur Kolom**: `id`, `notification_id` (unique index), `target_nip` (indexed), `title`, `body`, `type`, `status`, `retry_count`, `error_message`, `payload_json`, `created_at`, `updated_at`.

2. **`rekap_laporan_bulanan`**
   - **Fungsi**: Tabel penyimpanan hasil kalkulasi rekapitulasi laporan bulanan presensi pegawai/dosen (total masuk, izin, cuti, sppd, upacara, dan total libur).
   - **Struktur Kolom**: `id`, `nip`, `nidn`, `periode_type`, `periode_key`, `tanggal_mulai`, `tanggal_akhir`, `total_masuk`, `total_izin`, `total_cuti`, `total_sppd`, `total_upacara`, `total_libur`, `updated_at`.

3. **`master_libur`**
   - **Fungsi**: Penyimpanan data hari libur nasional dan libur kampus untuk memotong perhitungan otomatis absensi harian dan rekap bulanan.
   - **Struktur Kolom**: `id`, `holiday_id` (unique), `tanggal`, `nama`, `type`, `is_national_holiday`, `created_at`, `updated_at`.

4. **`export_jobs`**
   - **Fungsi**: Tabel pengelolaan antrean (*job queue*) untuk proses ekspor laporan rekap bulanan ke format Excel/PDF di background.

---

## 2. 🏛️ Tabel & View Lama Eksisting (*Existing Legacy Tables & Views*)

Tabel dan View bawaan lama dari skema awal `unpak_hrportal`:
- **`laporan_merge_absen_izin_cuti`**: Tabel/view gabungan absensi, izin, dan cuti.
- **`presensi_view`**: View agregasi profil pegawai/dosen SIMPEG dengan data absen harian.
- **`view_master_kalender_flat`**: View kalender kerja terpusat.
- **`view_pegawai`**: View data profil gabungan pegawai dan dosen dari SIMPEG.

---

## 3. 🛠️ Perubahan Struktur Kolom pada Tabel Eksisting (*Modified Schema*)

Perubahan kolom yang terjadi pada tabel yang sudah ada:

1. **Tabel `absen`**:
   - **Kolom Baru**: `note` (`varchar(10)`)
   - **Keterangan**: Ditambahkan untuk menyimpan kualifikasi status atau catatan khusus presensi harian pegawai.

---

## 4. 🧹 Tabel Legacy / Security Firewall yang Dibersihkan

Tabel-tabel firewall/security legacy bawaan PHP yang tidak lagi digunakan dan telah dibersihkan pada skema database aktif:
- `psec_bad-words`
- `psec_bans`
- `psec_bans-country`
- `psec_bans-other`
- `psec_bans-ranges`
- `psec_dnsbl-databases`
- `psec_file-whitelist`
- `psec_ip-whitelist`
- `psec_live-traffic`
- `psec_logins`
- `psec_logs`
- `psec_pages-layolt`

---

## 5. ⚠️ Tabel & View yang Tidak Digunakan (*Unused Tables & Views*)

Berikut adalah daftar 7 tabel dan view pada skema database `unpak_hrportal` yang **tidak digunakan** oleh backend Go & aplikasi Flutter HRPortal v2:

1. **`failed_jobs`**
   - **Keterangan**: Tabel legacy Laravel framework untuk mencatat kegagalan queue job PHP. Tidak digunakan oleh backend Go (Go menggunakan `export_jobs`).

2. **`migrations`**
   - **Keterangan**: Tabel legacy Laravel framework untuk mencatat riwayat migrasi skema PHP. Tidak digunakan oleh backend Go.

3. **`password_reset_tokens`**
   - **Keterangan**: Tabel legacy Laravel framework untuk penyimpanan token reset password PHP. Tidak digunakan oleh backend Go.

4. **`personal_access_tokens`**
   - **Keterangan**: Tabel legacy Laravel Sanctum authentication tokens. Backend Go menggunakan JWT token terenkripsi.

5. **`laporan_merge_absen_izin_cuti`**
   - **Keterangan**: View/tabel laporan gabungan lama. Backend Go kini menggunakan kueri gabungan langsung dan tabel `rekap_laporan_bulanan`.

6. **`presensi_view`**
   - **Keterangan**: View presensi gabungan lama. Backend Go melakukan kueri langsung ke tabel `absen` dan SIMPEG DB (`connect_m_dosen`, `connect_n_pribadi`, `connect_e_pribadi`).

7. **`view_master_kalender_flat`**
   - **Keterangan**: View kalender flat lama. Backend Go kini mengueri langsung tabel `master_kalender` dan `master_libur`.

---

*Diperbarui secara otomatis pada 23 Juli 2026.*
