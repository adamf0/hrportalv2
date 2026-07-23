package domain

import (
	"context"
)

type IIzinRepository interface {
	Create(ctx context.Context, izin *Izin) error
	Update(ctx context.Context, izin *Izin) error
	Delete(ctx context.Context, id uint) error
	GetByID(ctx context.Context, id uint) (*Izin, error)
	GetAll(ctx context.Context, nip string, nidn string, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]Izin, error)
}
