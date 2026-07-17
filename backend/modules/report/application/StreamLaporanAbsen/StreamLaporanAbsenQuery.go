package StreamLaporanAbsen

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/report/domain"
)

type StreamLaporanAbsenQuery struct {
	TanggalMulai string `json:"tanggal_mulai"`
	TanggalAkhir string `json:"tanggal_akhir"`
	Nip          string `json:"nip"`
	Nidn         string `json:"nidn"`
	UserType     string `json:"type"`
}

type StreamLaporanAbsenQueryHandler struct {
	repo domain.IReportRepository
}

func NewStreamLaporanAbsenQueryHandler(repo domain.IReportRepository) *StreamLaporanAbsenQueryHandler {
	return &StreamLaporanAbsenQueryHandler{repo: repo}
}

func (h *StreamLaporanAbsenQueryHandler) Handle(ctx context.Context, query *StreamLaporanAbsenQuery) (common.ResultValue[[]domain.FlatRecordItem], error) {
	data, err := h.repo.GetFlatLaporanMergedParallel(ctx, query.TanggalMulai, query.TanggalAkhir, query.Nip, query.Nidn, query.UserType)
	if err != nil {
		return common.FailureValue[[]domain.FlatRecordItem](domain.ReportNotFound()), err
	}
	return common.SuccessValue(data), nil
}
