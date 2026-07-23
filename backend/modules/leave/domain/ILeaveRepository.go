package domain

import (
	"context"
)

type ILeaveRepository interface {
	CreateCuti(ctx context.Context, cuti *Cuti) error
	FindByID(ctx context.Context, id uint) (*Cuti, error)
	UpdateCuti(ctx context.Context, cuti *Cuti) error
	DeleteCuti(ctx context.Context, id uint) error
	GetHistoryByNip(ctx context.Context, nip string, nidn string, verifikasi bool, isSdm bool, tanggal_mulai *string, tanggal_akhir *string) ([]Cuti, error)
	GetAllJenisCuti(ctx context.Context) ([]JenisCuti, error)
}
