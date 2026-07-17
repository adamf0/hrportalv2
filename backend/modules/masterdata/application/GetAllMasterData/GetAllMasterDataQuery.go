package GetAllMasterData

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/masterdata/domain"
)

// ----------------------------------------------------
// FAKULTAS
// ----------------------------------------------------
type GetAllFakultasQuery struct{}

type GetAllFakultasQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllFakultasQueryHandler(repo domain.IMasterDataRepository) *GetAllFakultasQueryHandler {
	return &GetAllFakultasQueryHandler{repo: repo}
}

func (h *GetAllFakultasQueryHandler) Handle(ctx context.Context, query *GetAllFakultasQuery) (common.ResultValue[[]domain.Fakultas], error) {
	list, err := h.repo.GetAllFakultas(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Fakultas](common.FailureError("MasterData.FakultasFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}

// ----------------------------------------------------
// PRODI
// ----------------------------------------------------
type GetAllProdiQuery struct{}

type GetAllProdiQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllProdiQueryHandler(repo domain.IMasterDataRepository) *GetAllProdiQueryHandler {
	return &GetAllProdiQueryHandler{repo: repo}
}

func (h *GetAllProdiQueryHandler) Handle(ctx context.Context, query *GetAllProdiQuery) (common.ResultValue[[]domain.Prodi], error) {
	list, err := h.repo.GetAllProdi(ctx)
	if err != nil {
		return common.FailureValue[[]domain.Prodi](common.FailureError("MasterData.ProdiFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}

// ----------------------------------------------------
// JENIS CUTI
// ----------------------------------------------------
type GetAllJenisCutiQuery struct{}

type GetAllJenisCutiQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisCutiQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisCutiQueryHandler {
	return &GetAllJenisCutiQueryHandler{repo: repo}
}

func (h *GetAllJenisCutiQueryHandler) Handle(ctx context.Context, query *GetAllJenisCutiQuery) (common.ResultValue[[]domain.JenisCuti], error) {
	list, err := h.repo.GetAllJenisCuti(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisCuti](common.FailureError("MasterData.JenisCutiFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}

// ----------------------------------------------------
// JENIS IZIN
// ----------------------------------------------------
type GetAllJenisIzinQuery struct{}

type GetAllJenisIzinQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisIzinQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisIzinQueryHandler {
	return &GetAllJenisIzinQueryHandler{repo: repo}
}

func (h *GetAllJenisIzinQueryHandler) Handle(ctx context.Context, query *GetAllJenisIzinQuery) (common.ResultValue[[]domain.JenisIzin], error) {
	list, err := h.repo.GetAllJenisIzin(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisIzin](common.FailureError("MasterData.JenisIzinFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}

// ----------------------------------------------------
// JENIS SPPD
// ----------------------------------------------------
type GetAllJenisSppdQuery struct{}

type GetAllJenisSppdQueryHandler struct {
	repo domain.IMasterDataRepository
}

func NewGetAllJenisSppdQueryHandler(repo domain.IMasterDataRepository) *GetAllJenisSppdQueryHandler {
	return &GetAllJenisSppdQueryHandler{repo: repo}
}

func (h *GetAllJenisSppdQueryHandler) Handle(ctx context.Context, query *GetAllJenisSppdQuery) (common.ResultValue[[]domain.JenisSppd], error) {
	list, err := h.repo.GetAllJenisSppd(ctx)
	if err != nil {
		return common.FailureValue[[]domain.JenisSppd](common.FailureError("MasterData.JenisSppdFailed", err.Error())), nil
	}
	return common.SuccessValue(list), nil
}
