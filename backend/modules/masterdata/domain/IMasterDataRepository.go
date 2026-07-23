package domain

import (
	"context"
)

type IMasterDataRepository interface {
	GetAllFakultas(ctx context.Context) ([]Fakultas, error)
	GetAllProdi(ctx context.Context) ([]Prodi, error)
	GetAllJenisCuti(ctx context.Context) ([]JenisCuti, error)
	GetAllJenisIzin(ctx context.Context) ([]JenisIzin, error)
	GetAllJenisSppd(ctx context.Context) ([]JenisSppd, error)
	GetVerifikators(ctx context.Context, verifikatorType string) ([]Verifikator, error)
}
