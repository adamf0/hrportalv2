package domain

import (
	"context"
)

type ISppdRepository interface {
	CreateSppd(ctx context.Context, sppd *Sppd) error
	FindByID(ctx context.Context, id uint) (*Sppd, error)
	UpdateSppd(ctx context.Context, sppd *Sppd) error
	DeleteSppd(ctx context.Context, id uint) error
	GetHistoryByNip(ctx context.Context, nip string, nidn string, isSdm bool) ([]Sppd, error)
}
