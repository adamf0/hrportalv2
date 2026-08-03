package domain

import (
	"context"
)

type ICeremonyAttendanceRepository interface {
	Create(ctx context.Context, upacara *AbsenUpacara) error
	Update(ctx context.Context, upacara *AbsenUpacara) error
	Delete(ctx context.Context, id uint) error
	GetByID(ctx context.Context, id uint) (*AbsenUpacara, error)
	GetAll(ctx context.Context, nip string, nidn string, tanggal string) ([]AbsenUpacara, error)
}
