package domain

import (
	"context"
	"time"

	common "hrportal_backend/common/domain"
)

type AbsenUpacara struct {
	common.Entity
	ID        uint       `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	Nidn      string     `gorm:"column:nidn" json:"nidn"`
	Nip       string     `gorm:"column:nip" json:"nip"`
	Tanggal   string     `gorm:"column:tanggal;type:date" json:"tanggal"`
	CreatedAt *time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt *time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (AbsenUpacara) TableName() string {
	return "absen_upacara"
}

type ICeremonyAttendanceRepository interface {
	Create(ctx context.Context, upacara *AbsenUpacara) error
	Update(ctx context.Context, upacara *AbsenUpacara) error
	Delete(ctx context.Context, id uint) error
	GetByID(ctx context.Context, id uint) (*AbsenUpacara, error)
	GetAll(ctx context.Context, nip string, nidn string, tanggal string) ([]AbsenUpacara, error)
}
