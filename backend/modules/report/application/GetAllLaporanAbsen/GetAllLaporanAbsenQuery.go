package GetAllLaporanAbsen

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/report/domain"
)

type GetAllLaporanAbsenQuery struct {
	TanggalMulai string `json:"tanggal_mulai"`
	TanggalAkhir string `json:"tanggal_akhir"`
	Nip          string `json:"nip"`
	Nidn         string `json:"nidn"`
}

type GetAllLaporanAbsenQueryHandler struct {
	repo domain.IReportRepository
}

func NewGetAllLaporanAbsenQueryHandler(repo domain.IReportRepository) *GetAllLaporanAbsenQueryHandler {
	return &GetAllLaporanAbsenQueryHandler{repo: repo}
}

func (h *GetAllLaporanAbsenQueryHandler) Handle(ctx context.Context, query *GetAllLaporanAbsenQuery) (common.ResultValue[map[string]interface{}], error) {
	dataList, err := h.repo.GetLaporanMergedParallel(ctx, query.TanggalMulai, query.TanggalAkhir, query.Nip, query.Nidn, "")
	if err != nil {
		return common.FailureValue[map[string]interface{}](domain.ReportNotFound()), err
	}
	return common.SuccessValue(map[string]interface{}{
		"list_data": dataList,
	}), nil
}
