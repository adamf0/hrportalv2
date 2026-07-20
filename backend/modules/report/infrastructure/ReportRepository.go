package infrastructure

import (
	"context"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	commoninfra "hrportal_backend/common/infrastructure"
	accountDomain "hrportal_backend/modules/account/domain"
	attendanceDomain "hrportal_backend/modules/attendance/domain"
	permissionDomain "hrportal_backend/modules/izin/domain"
	leaveDomain "hrportal_backend/modules/leave/domain"
	"hrportal_backend/modules/report/domain"
	sppdDomain "hrportal_backend/modules/sppd/domain"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type ReportRepository struct {
	db *gorm.DB
}

func NewReportRepository(db *gorm.DB) domain.IReportRepository {
	return &ReportRepository{db: db}
}

func (r *ReportRepository) GetDB() *gorm.DB {
	return r.db
}

func (r *ReportRepository) IncrementCounter(ctx context.Context, nip string, nidn string, date time.Time, counterType string) error {
	nipClean := strings.TrimSpace(nip)
	nidnClean := strings.TrimSpace(nidn)
	if nipClean == "" && nidnClean == "" {
		return nil
	}
	nip = nipClean
	nidn = nidnClean

	calStart := time.Date(date.Year(), date.Month(), 1, 0, 0, 0, 0, date.Location())
	calEnd := calStart.AddDate(0, 1, -1)
	calKey := calStart.Format("2006-01")

	var cutStart, cutEnd time.Time
	var cutKey string

	if date.Day() < 16 {
		cutStart = time.Date(date.Year(), date.Month()-1, 16, 0, 0, 0, 0, date.Location())
		cutEnd = time.Date(date.Year(), date.Month(), 15, 0, 0, 0, 0, date.Location())
		cutKey = date.Format("2006-01")
	} else {
		cutStart = time.Date(date.Year(), date.Month(), 16, 0, 0, 0, 0, date.Location())
		cutEnd = time.Date(date.Year(), date.Month()+1, 15, 0, 0, 0, 0, date.Location())
		cutKey = date.AddDate(0, 1, 0).Format("2006-01")
	}

	periods := []struct {
		pType domain.PeriodeType
		pKey  string
		start string
		end   string
	}{
		{domain.PeriodeCalendar, calKey, calStart.Format("2006-01-02"), calEnd.Format("2006-01-02")},
		{domain.PeriodeCutoff, cutKey, cutStart.Format("2006-01-02"), cutEnd.Format("2006-01-02")},
	}

	for _, p := range periods {
		now := time.Now()
		item := domain.RekapLaporanBulanan{
			Nip:          nip,
			Nidn:         nidn,
			PeriodeType:  p.pType,
			PeriodeKey:   p.pKey,
			TanggalMulai: p.start,
			TanggalAkhir: p.end,
			UpdatedAt:    &now,
		}

		switch counterType {
		case "masuk":
			item.TotalMasuk = 1
		case "izin":
			item.TotalIzin = 1
		case "cuti":
			item.TotalCuti = 1
		case "sppd":
			item.TotalSppd = 1
		case "upacara":
			item.TotalUpacara = 1
		}

		columnToInc := "total_" + counterType

		conflictCols := []clause.Column{{Name: "nip"}, {Name: "nidn"}, {Name: "periode_type"}, {Name: "periode_key"}}

		err := commoninfra.GetTx(ctx, r.db).Clauses(clause.OnConflict{
			Columns: conflictCols,
			DoUpdates: clause.Assignments(map[string]interface{}{
				columnToInc:  gorm.Expr("rekap_laporan_bulanan."+columnToInc+" + ?", 1),
				"updated_at": now,
			}),
		}).Create(&item).Error

		if err != nil {
			return err
		}
	}

	return nil
}

func (r *ReportRepository) GetReportSummary(ctx context.Context, nip string, periodeType domain.PeriodeType, periodeKey string) (*domain.RekapLaporanBulanan, error) {
	var rekap domain.RekapLaporanBulanan
	err := r.db.WithContext(ctx).
		Where("nip = ? AND periode_type = ? AND periode_key = ?", nip, periodeType, periodeKey).
		First(&rekap).Error
	if err != nil {
		return nil, err
	}
	return &rekap, nil
}

func (r *ReportRepository) GetAllLaporanAbsen(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string) (map[string]interface{}, error) {
	now := time.Now()

	// 1. Versi 1 (Calendar Month)
	v1Start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	v1End := v1Start.AddDate(0, 1, -1)
	v1Key := v1Start.Format("2006-01")

	var rekapsV1 []domain.RekapLaporanBulanan
	q1 := r.db.WithContext(ctx).Model(&domain.RekapLaporanBulanan{}).
		Where("periode_type = ? AND periode_key = ?", domain.PeriodeCalendar, v1Key)
	if nip != "" {
		q1 = q1.Where("nip = ?", nip)
	}
	if nidn != "" {
		q1 = q1.Where("nidn = ?", nidn)
	}
	q1.Find(&rekapsV1)

	// 2. Versi 2 (Cutoff Period)
	v2Start := time.Date(now.Year(), now.Month()-1, 16, 0, 0, 0, 0, now.Location())
	v2End := time.Date(now.Year(), now.Month(), 15, 0, 0, 0, 0, now.Location())
	v2Key := now.Format("2006-01")

	var rekapsV2 []domain.RekapLaporanBulanan
	q2 := r.db.WithContext(ctx).Model(&domain.RekapLaporanBulanan{}).
		Where("periode_type = ? AND periode_key = ?", domain.PeriodeCutoff, v2Key)
	if nip != "" {
		q2 = q2.Where("nip = ?", nip)
	}
	if nidn != "" {
		q2 = q2.Where("nidn = ?", nidn)
	}
	q2.Find(&rekapsV2)

	return map[string]interface{}{
		"versi_1_calendar": map[string]interface{}{
			"start":     v1Start.Format("02 January 2006"),
			"end":       v1End.Format("02 January 2006"),
			"list_data": rekapsV1,
		},
		"versi_2_cutoff": map[string]interface{}{
			"start":     v2Start.Format("02 January 2006"),
			"end":       v2End.Format("02 January 2006"),
			"list_data": rekapsV2,
		},
	}, nil
}

func (r *ReportRepository) GetLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]domain.LaporanPenggunaMerged, error) {
	if tanggalMulai == "" {
		tanggalMulai = time.Now().Format("2006-01") + "-01"
	}
	if tanggalAkhir == "" {
		tanggalAkhir = time.Now().Format("2006-01-02")
	}

	var (
		wg       sync.WaitGroup
		pegawais []accountDomain.Pegawai
		absens   []attendanceDomain.Absen
		izins    []permissionDomain.Izin
		cutis    []leaveDomain.Cuti
		sppds    []sppdDomain.Sppd
		upacaras []attendanceDomain.AbsenUpacara
	)

	wg.Add(5)

	// Query 1: Pegawai
	go func() {
		defer wg.Done()
		q := r.db.WithContext(ctx).Table("connect_payroll_m_pegawai cpmp").
			Select("cpmp.id_pegawai as id, cpmp.nip as nip, coalesce(cep.nidn, '') as nidn, cpmp.nama as nama, null as email, null as unit_kerja, coalesce(cpmp.fungsional, '') as jabatan").
			Joins("left join connect_e_pribadi cep on cpmp.nip = cep.nip")
		if nip != "" {
			q = q.Where("cpmp.nip = ?", nip)
		}
		if nidn != "" {
			q = q.Where("cep.nidn = ?", nidn)
		}
		q.Find(&pegawais)
	}()

	// Query 2: Absen Masuk
	go func() {
		defer wg.Done()
		q := r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).
			Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", tanggalMulai, tanggalAkhir)
		if nip != "" {
			q = q.Where("nip = ? OR nidn = ?", nip, nidn)
		}
		if nidn != "" {
			q = q.Where("nidn = ? OR nip = ?", nidn, nidn)
		}
		q.Find(&absens)
	}()

	// Query 3: Izin
	go func() {
		defer wg.Done()
		q := r.db.WithContext(ctx).Model(&permissionDomain.Izin{}).
			Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND status = 'terima sdm'", tanggalMulai, tanggalAkhir)
		if nip != "" {
			q = q.Where("nip = ? OR nidn = ?", nip, nidn)
		}
		if nidn != "" {
			q = q.Where("nidn = ? OR nip = ?", nidn, nidn)
		}
		q.Find(&izins)
	}()

	// Query 4: Cuti
	go func() {
		defer wg.Done()
		q := r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}).
			Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND status = 'terima sdm'", tanggalAkhir, tanggalMulai)
		if nip != "" {
			q = q.Where("nip = ? OR nidn = ?", nip, nidn)
		}
		if nidn != "" {
			q = q.Where("nidn = ? OR nip = ?", nidn, nidn)
		}
		q.Find(&cutis)
	}()

	// Query 5: SPPD & Upacara
	go func() {
		defer wg.Done()
		q := r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}).
			Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND status = 'terima sdm'", tanggalAkhir, tanggalMulai)
		if nip != "" {
			q = q.Where("nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?)", nip, nidn, nip, nidn)
		}
		if nidn != "" {
			q = q.Where("nidn = ? OR nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ? OR nip = ?)", nidn, nidn, nidn, nidn)
		}
		q.Find(&sppds)

		qu := r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}).
			Where("tanggal >= ? AND tanggal <= ?", tanggalMulai, tanggalAkhir)
		if nip != "" {
			qu = qu.Where("nip = ? OR nidn = ?", nip, nidn)
		}
		if nidn != "" {
			qu = qu.Where("nidn = ? OR nip = ?", nidn, nidn)
		}
		qu.Find(&upacaras)
	}()

	wg.Wait()

	var sppdIds []uint
	for _, sp := range sppds {
		sppdIds = append(sppdIds, sp.ID)
	}

	var sppdAnggotas []sppdDomain.SppdAnggota
	if len(sppdIds) > 0 {
		r.db.WithContext(ctx).Model(&sppdDomain.SppdAnggota{}).Where("id_sppd IN ?", sppdIds).Find(&sppdAnggotas)
	}

	// Map to look up members by SppdID quickly
	anggotaBySppdID := make(map[uint][]sppdDomain.SppdAnggota)
	for _, sa := range sppdAnggotas {
		anggotaBySppdID[sa.SppdID] = append(anggotaBySppdID[sa.SppdID], sa)
	}

	recordsByNip := make(map[string][]domain.RecordItem)
	recordsByNidn := make(map[string][]domain.RecordItem)

	for _, a := range absens {
		rec := domain.RecordItem{
			ID:      a.ID,
			Tanggal: a.Tanggal,
			Type:    "absen",
			Info: map[string]interface{}{
				"masuk":  a.AbsenMasuk,
				"keluar": a.AbsenKeluar,
			},
		}
		if a.Nip != "" {
			recordsByNip[a.Nip] = append(recordsByNip[a.Nip], rec)
		} else if a.Nidn != "" {
			recordsByNidn[a.Nidn] = append(recordsByNidn[a.Nidn], rec)
		}
	}

	for _, iz := range izins {
		rec := domain.RecordItem{
			ID:      iz.ID,
			Tanggal: iz.TanggalPengajuan,
			Type:    "izin",
			Info: map[string]interface{}{
				"tujuan": iz.Tujuan,
			},
		}
		if iz.Nip != "" {
			recordsByNip[iz.Nip] = append(recordsByNip[iz.Nip], rec)
		} else if iz.Nidn != "" {
			recordsByNidn[iz.Nidn] = append(recordsByNidn[iz.Nidn], rec)
		}
	}

	for _, c := range cutis {
		rec := domain.RecordItem{
			ID:      c.ID,
			Tanggal: c.TanggalMulai,
			Type:    "cuti",
			Info: map[string]interface{}{
				"alasan": c.Alasan,
				"status": c.Status,
			},
		}
		if c.Nip != "" {
			recordsByNip[c.Nip] = append(recordsByNip[c.Nip], rec)
		} else if c.Nidn != "" {
			recordsByNidn[c.Nidn] = append(recordsByNidn[c.Nidn], rec)
		}
	}

	for _, sp := range sppds {
		rec := domain.RecordItem{
			ID:      sp.ID,
			Tanggal: sp.TanggalBerangkat,
			Type:    "sppd",
			Info: map[string]interface{}{
				"maksud": sp.Keterangan,
				"tujuan": sp.Tujuan,
			},
		}
		if sp.Nip != "" {
			recordsByNip[sp.Nip] = append(recordsByNip[sp.Nip], rec)
		} else if sp.Nidn != "" {
			recordsByNidn[sp.Nidn] = append(recordsByNidn[sp.Nidn], rec)
		}

		for _, member := range anggotaBySppdID[sp.ID] {
			if member.Nip != "" {
				recordsByNip[member.Nip] = append(recordsByNip[member.Nip], rec)
			} else if member.Nidn != "" {
				recordsByNidn[member.Nidn] = append(recordsByNidn[member.Nidn], rec)
			}
		}
	}

	for _, u := range upacaras {
		rec := domain.RecordItem{
			ID:      u.ID,
			Tanggal: u.Tanggal,
			Type:    "upacara",
			Info: map[string]interface{}{
				"tanggal": u.Tanggal,
			},
		}
		if u.Nip != "" {
			recordsByNip[u.Nip] = append(recordsByNip[u.Nip], rec)
		} else if u.Nidn != "" {
			recordsByNidn[u.Nidn] = append(recordsByNidn[u.Nidn], rec)
		}
	}

	var results []domain.LaporanPenggunaMerged
	for _, p := range pegawais {
		kode := "NA"
		userTypeVal := "NA"
		if p.Nidn != "" {
			kode = p.Nidn
			userTypeVal = "dosen"
		} else if p.Nip != "" {
			kode = p.Nip
			userTypeVal = "pegawai"
		}

		recs := recordsByNip[p.Nip]
		if len(recs) == 0 && p.Nidn != "" {
			recs = recordsByNidn[p.Nidn]
		}
		if recs == nil {
			recs = []domain.RecordItem{}
		}

		results = append(results, domain.LaporanPenggunaMerged{
			Kode:     kode,
			Pengguna: p,
			Type:     userTypeVal,
			Records:  recs,
		})
	}

	return results, nil
}

func (r *ReportRepository) GetFlatLaporanMergedParallel(ctx context.Context, tanggalMulai string, tanggalAkhir string, nip string, nidn string, userType string) ([]domain.FlatRecordItem, error) {
	merged, err := r.GetLaporanMergedParallel(ctx, tanggalMulai, tanggalAkhir, nip, nidn, userType)
	if err != nil {
		return nil, err
	}

	var flatList []domain.FlatRecordItem
	for _, m := range merged {
		for _, rec := range m.Records {
			flatList = append(flatList, domain.FlatRecordItem{
				ID:       rec.ID,
				Tanggal:  rec.Tanggal,
				Type:     rec.Type,
				Info:     rec.Info,
				Pengguna: m.Pengguna,
			})
		}
	}

	return flatList, nil
}

func (r *ReportRepository) CalculateReport(ctx context.Context) (map[string]interface{}, error) {
	// Query unique employees from local activity tables to bypass view_pegawai (connect_m_dosen, connect_e_pribadi, connect_n_pribadi queries)
	type employee struct {
		Nip  string `gorm:"column:nip"`
		Nidn string `gorm:"column:nidn"`
	}
	empSet := make(map[employee]bool)

	var eAbsen []employee
	r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).Select("DISTINCT nip, nidn").Find(&eAbsen)
	for _, e := range eAbsen {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eIzin []employee
	r.db.WithContext(ctx).Model(&permissionDomain.Izin{}).Select("DISTINCT nip, nidn").Find(&eIzin)
	for _, e := range eIzin {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eCuti []employee
	r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}).Select("DISTINCT nip, nidn").Find(&eCuti)
	for _, e := range eCuti {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eSppd []employee
	r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}).Select("DISTINCT nip, nidn").Find(&eSppd)
	for _, e := range eSppd {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eSppdAnggota []employee
	r.db.WithContext(ctx).Model(&sppdDomain.SppdAnggota{}).Select("DISTINCT nip, nidn").Find(&eSppdAnggota)
	for _, e := range eSppdAnggota {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var eUpacara []employee
	r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}).Select("DISTINCT nip, nidn").Find(&eUpacara)
	for _, e := range eUpacara {
		if e.Nip != "" || e.Nidn != "" {
			empSet[e] = true
		}
	}

	var pegawais []accountDomain.Pegawai
	for emp := range empSet {
		nipVal := strings.TrimSpace(emp.Nip)
		nidnVal := strings.TrimSpace(emp.Nidn)
		if (nipVal == "" || nipVal == "-" || nipVal == "--") && (nidnVal == "" || nidnVal == "-" || nidnVal == "--") {
			continue
		}
		pegawais = append(pegawais, accountDomain.Pegawai{
			Nip:  nipVal,
			Nidn: nidnVal,
		})
	}

	var writeMu sync.Mutex

	var months []string
	// Find distinct months across all activity tables filtered by status
	var mAbsen, mIzin, mCuti, mSppd, mUpacara []string
	qAbsen := r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}).Where("absen_masuk IS NOT NULL")
	qIzin := r.db.WithContext(ctx).Model(&permissionDomain.Izin{}).Where("status = 'terima sdm'")
	qCuti := r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}).Where("status = 'terima sdm'")
	qSppd := r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}).Where("status = 'terima sdm'")
	qUpacara := r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{})

	qAbsen.Select("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')", &mAbsen)
	qIzin.Select("DISTINCT DATE_FORMAT(tanggal_pengajuan, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_pengajuan, '%Y-%m')", &mIzin)
	qCuti.Select("DISTINCT DATE_FORMAT(tanggal_mulai, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_mulai, '%Y-%m')", &mCuti)
	qSppd.Select("DISTINCT DATE_FORMAT(tanggal_berangkat, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal_berangkat, '%Y-%m')", &mSppd)
	qUpacara.Select("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')").Pluck("DISTINCT DATE_FORMAT(tanggal, '%Y-%m')", &mUpacara)

	monthSet := make(map[string]bool)
	for _, list := range [][]string{mAbsen, mIzin, mCuti, mSppd, mUpacara} {
		for _, m := range list {
			if m != "" {
				monthSet[m] = true
			}
		}
	}

	if len(monthSet) == 0 {
		monthSet[time.Now().Format("2006-01")] = true
	}

	for m := range monthSet {
		months = append(months, m)
	}

	now := time.Now()
	var totalRecordsProcessed int64

	for _, mStr := range months {
		refDate, err := time.Parse("2006-01", mStr)
		if err != nil {
			continue
		}

		// 1. Versi 1 (Calendar Month: 1st to last day)
		v1Start := time.Date(refDate.Year(), refDate.Month(), 1, 0, 0, 0, 0, refDate.Location())
		v1End := v1Start.AddDate(0, 1, -1)
		v1Key := v1Start.Format("2006-01")

		// 2. Versi 2 (Cutoff Period: 15th of prev month to 14th of curr month)
		v2Start := time.Date(refDate.Year(), refDate.Month()-1, 16, 0, 0, 0, 0, refDate.Location())
		v2End := time.Date(refDate.Year(), refDate.Month(), 15, 0, 0, 0, 0, refDate.Location())
		v2Key := refDate.Format("2006-01")

		var cLiburV1, cLiburV2 int64
		r.db.WithContext(ctx).Table("master_libur").
			Where("tanggal >= ? AND tanggal <= ? AND (is_national_holiday = 1 OR type LIKE '%Holiday%')", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
			Count(&cLiburV1)

		r.db.WithContext(ctx).Table("master_libur").
			Where("tanggal >= ? AND tanggal <= ? AND (is_national_holiday = 1 OR type LIKE '%Holiday%')", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
			Count(&cLiburV2)

		type job struct {
			p accountDomain.Pegawai
		}
		jobs := make(chan job, len(pegawais))
		for _, p := range pegawais {
			jobs <- job{p: p}
		}
		close(jobs)

		var wgWorkers sync.WaitGroup
		numWorkers := 10 // Safe concurrent database workers
		for w := 1; w <= numWorkers; w++ {
			wgWorkers.Add(1)
			go func() {
				defer wgWorkers.Done()
				for j := range jobs {
					p := j.p
					nipVal := strings.TrimSpace(p.Nip)
					nidnVal := strings.TrimSpace(p.Nidn)
					if nipVal == "" && nidnVal == "" {
						continue
					}

					var cMasukV1, cIzinV1, cCutiV1, cSppdV1, cUpacaraV1 int64
					var cMasukV2, cIzinV2, cCutiV2, cSppdV2, cUpacaraV2 int64

					var wgCount sync.WaitGroup
					wgCount.Add(10)

					// Count V1 Calendar in parallel
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cMasukV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&permissionDomain.Izin{}), nipVal, nidnVal).
							Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND status = 'terima sdm'", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cIzinV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}), nipVal, nidnVal).
							Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND status = 'terima sdm'", v1End.Format("2006-01-02"), v1Start.Format("2006-01-02")).
							Count(&cCutiV1)
					}()
					go func() {
						defer wgCount.Done()
						buildSppdUserWhere(r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}), nipVal, nidnVal).
							Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND status = 'terima sdm'", v1End.Format("2006-01-02"), v1Start.Format("2006-01-02")).
							Count(&cSppdV1)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ?", v1Start.Format("2006-01-02"), v1End.Format("2006-01-02")).
							Count(&cUpacaraV1)
					}()

					// Count V2 Cutoff in parallel
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.Absen{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ? AND absen_masuk IS NOT NULL", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cMasukV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&permissionDomain.Izin{}), nipVal, nidnVal).
							Where("tanggal_pengajuan >= ? AND tanggal_pengajuan <= ? AND status = 'terima sdm'", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cIzinV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&leaveDomain.Cuti{}), nipVal, nidnVal).
							Where("tanggal_mulai <= ? AND tanggal_akhir >= ? AND status = 'terima sdm'", v2End.Format("2006-01-02"), v2Start.Format("2006-01-02")).
							Count(&cCutiV2)
					}()
					go func() {
						defer wgCount.Done()
						buildSppdUserWhere(r.db.WithContext(ctx).Model(&sppdDomain.Sppd{}), nipVal, nidnVal).
							Where("tanggal_berangkat <= ? AND tanggal_kembali >= ? AND status = 'terima sdm'", v2End.Format("2006-01-02"), v2Start.Format("2006-01-02")).
							Count(&cSppdV2)
					}()
					go func() {
						defer wgCount.Done()
						buildUserWhere(r.db.WithContext(ctx).Model(&attendanceDomain.AbsenUpacara{}), nipVal, nidnVal).
							Where("tanggal >= ? AND tanggal <= ?", v2Start.Format("2006-01-02"), v2End.Format("2006-01-02")).
							Count(&cUpacaraV2)
					}()

					wgCount.Wait()

					itemV1 := domain.RekapLaporanBulanan{
						Nip:          nipVal,
						Nidn:         nidnVal,
						PeriodeType:  domain.PeriodeCalendar,
						PeriodeKey:   v1Key,
						TanggalMulai: v1Start.Format("2006-01-02"),
						TanggalAkhir: v1End.Format("2006-01-02"),
						TotalMasuk:   int(cMasukV1),
						TotalIzin:    int(cIzinV1),
						TotalCuti:    int(cCutiV1),
						TotalSppd:    int(cSppdV1),
						TotalUpacara: int(cUpacaraV1),
						TotalLibur:   int(cLiburV1),
						UpdatedAt:    &now,
					}
					conflictCols := []clause.Column{{Name: "nip"}, {Name: "nidn"}, {Name: "periode_type"}, {Name: "periode_key"}}

					writeMu.Lock()
					r.db.WithContext(ctx).Clauses(clause.OnConflict{
						Columns:   conflictCols,
						UpdateAll: true,
					}).Create(&itemV1)

					itemV2 := domain.RekapLaporanBulanan{
						Nip:          nipVal,
						Nidn:         nidnVal,
						PeriodeType:  domain.PeriodeCutoff,
						PeriodeKey:   v2Key,
						TanggalMulai: v2Start.Format("2006-01-02"),
						TanggalAkhir: v2End.Format("2006-01-02"),
						TotalMasuk:   int(cMasukV2),
						TotalIzin:    int(cIzinV2),
						TotalCuti:    int(cCutiV2),
						TotalSppd:    int(cSppdV2),
						TotalUpacara: int(cUpacaraV2),
						TotalLibur:   int(cLiburV2),
						UpdatedAt:    &now,
					}
					r.db.WithContext(ctx).Clauses(clause.OnConflict{
						Columns:   conflictCols,
						UpdateAll: true,
					}).Create(&itemV2)
					writeMu.Unlock()

					atomic.AddInt64(&totalRecordsProcessed, 2)
				}
			}()
		}
		wgWorkers.Wait()
	}

	return map[string]interface{}{
		"status":                  "success",
		"message":                 "Kalkulasi ulang laporan versi 1 dan versi 2 untuk seluruh data pegawai dan bulan telah selesai",
		"total_bulan_dikalkulasi": len(months),
		"total_pegawai":           len(pegawais),
		"total_rekap_records":     int(totalRecordsProcessed),
		"daftar_bulan":            months,
	}, nil
}

func buildUserWhere(db *gorm.DB, nip, nidn string) *gorm.DB {
	if nip != "" && nidn != "" {
		return db.Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		return db.Where("nip = ?", nip)
	} else if nidn != "" {
		return db.Where("nidn = ?", nidn)
	}
	return db.Where("1 = 0")
}

func buildSppdUserWhere(db *gorm.DB, nip, nidn string) *gorm.DB {
	if nip != "" && nidn != "" {
		return db.Where("(nip = ? OR nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ? OR nidn = ?))", nip, nidn, nip, nidn)
	} else if nip != "" {
		return db.Where("(nip = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nip = ?))", nip, nip)
	} else if nidn != "" {
		return db.Where("(nidn = ? OR id IN (SELECT id_sppd FROM sppd_anggota WHERE nidn = ?))", nidn, nidn)
	}
	return db.Where("1 = 0")
}
