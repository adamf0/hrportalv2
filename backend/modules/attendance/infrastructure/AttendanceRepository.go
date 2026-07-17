package infrastructure

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/attendance/domain"

	"gorm.io/gorm"
)

type AttendanceRepository struct {
	db *gorm.DB
}

func NewAttendanceRepository(db *gorm.DB) domain.IAttendanceRepository {
	return &AttendanceRepository{db: db}
}

func (r *AttendanceRepository) FindByNipAndTanggal(ctx context.Context, nip string, nidn string, tanggal string) (*domain.Absen, error) {
	var absen domain.Absen
	err := r.db.WithContext(ctx).
		Where("(nip = ? OR nidn = ? ) AND tanggal = ?", nip, tanggal).
		First(&absen).Error
	if err != nil {
		return nil, err
	}
	return &absen, nil
}

func (r *AttendanceRepository) CreateAbsen(ctx context.Context, absen *domain.Absen) error {
	return r.db.WithContext(ctx).Create(absen).Error
}

func (r *AttendanceRepository) UpdateAbsen(ctx context.Context, absen *domain.Absen) error {
	return r.db.WithContext(ctx).Save(absen).Error
}

func (r *AttendanceRepository) GetHistoryByNip(ctx context.Context, nip string, nidn string, page int, pageSize int) (common.Paged[domain.Absen], error) {
	var items []domain.Absen
	var total int64

	var query *gorm.DB
	if nip != "" && nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Absen{}).Where("(nip = ? OR nidn = ?)", nip, nidn)
	} else if nip != "" {
		query = r.db.WithContext(ctx).Model(&domain.Absen{}).Where("nip = ?", nip)
	} else if nidn != "" {
		query = r.db.WithContext(ctx).Model(&domain.Absen{}).Where("nidn = ?", nidn)
	} else {
		return common.NewPaged[domain.Absen](nil, 0, page, pageSize), nil
	}
	query = query.Where("absen_masuk IS NOT NULL")
	query.Count(&total)

	if pageSize <= 0 {
		pageSize = 10
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * pageSize

	err := query.Order("tanggal desc").Offset(offset).Limit(pageSize).Find(&items).Error
	if err != nil {
		return common.NewPaged[domain.Absen](nil, 0, page, pageSize), err
	}

	return common.NewPaged(items, total, page, pageSize), nil
}

func (r *AttendanceRepository) CreateKlaim(ctx context.Context, klaim *domain.KlaimAbsen) error {
	return r.db.WithContext(ctx).Create(klaim).Error
}

func (r *AttendanceRepository) FindByNipAndTanggalUpacara(ctx context.Context, nip string, nidn string, tanggal string) (*domain.AbsenUpacara, error) {
	var upacara domain.AbsenUpacara
	err := r.db.WithContext(ctx).
		Where("(nip = ? OR nidn = ? ) AND tanggal = ?", nip, tanggal).
		First(&upacara).Error
	if err != nil {
		return nil, err
	}
	return &upacara, nil
}

func (r *AttendanceRepository) CreateAbsenUpacara(ctx context.Context, upacara *domain.AbsenUpacara) error {
	return r.db.WithContext(ctx).Create(upacara).Error
}

func (r *AttendanceRepository) DeleteEmptyAbsen(ctx context.Context) (int64, error) {
	res := r.db.WithContext(ctx).
		Where("absen_masuk IS NULL OR TRIM(absen_masuk) = '' OR absen_masuk = '0000-00-00 00:00:00'").
		Delete(&domain.Absen{})
	return res.RowsAffected, res.Error
}
