package infrastructure

import (
	"context"

	commoninfra "hrportal_backend/common/infrastructure"
	"hrportal_backend/modules/izin/domain"

	"gorm.io/gorm"
)

type IzinRepository struct {
	db *gorm.DB
}

func NewIzinRepository(db *gorm.DB) domain.IIzinRepository {
	return &IzinRepository{db: db}
}

func (r *IzinRepository) Create(ctx context.Context, izin *domain.Izin) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Create(izin).Error
}

func (r *IzinRepository) Update(ctx context.Context, izin *domain.Izin) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Save(izin).Error
}

func (r *IzinRepository) Delete(ctx context.Context, id uint) error {
	if r == nil || r.db == nil {
		return nil
	}
	return commoninfra.GetTx(ctx, r.db).Delete(&domain.Izin{}, id).Error
}

func (r *IzinRepository) GetByID(ctx context.Context, id uint) (*domain.Izin, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}
	var izin domain.Izin
	err := commoninfra.GetTx(ctx, r.db).Debug().First(&izin, id).Error
	if err != nil {
		return nil, err
	}
	return &izin, nil
}

func (r *IzinRepository) GetAll(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]domain.Izin, error) {
	if r == nil || r.db == nil {
		return []domain.Izin{}, nil
	}
	var izins []domain.Izin
	query := commoninfra.GetTx(ctx, r.db).Debug().Model(&domain.Izin{})

	if isSdm && (tanggal_mulai != nil && *tanggal_mulai != "" && tanggal_akhir != nil && *tanggal_akhir != "") {
		query = query.Where("tanggal_pengajuan between ? and ?", *tanggal_mulai, *tanggal_akhir)
	} else if nip != "" || nidn != "" {
		if nip != "" && nidn != "" {
			if verifikasi {
				query = query.Where("verifikasi = ? or verifikasi = ?", nip, nidn)
			} else {
				query = query.Where("(nip = ? OR nidn = ?)", nip, nidn)
			}
		} else if nip != "" {
			if verifikasi {
				query = query.Where("verifikasi = ?", nip)
			} else {
				query = query.Where("nip = ?", nip)
			}
		} else {
			if verifikasi {
				query = query.Where("verifikasi = ?", nidn)
			} else {
				query = query.Where("nidn = ?", nidn)
			}
		}
	}

	err := query.Order("tanggal_pengajuan desc").Find(&izins).Error
	if err != nil {
		return nil, err
	}
	return izins, nil
}
