package GetSummaryReport

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/report/domain"
)

type GetSummaryReportQuery struct {
	Nip         string             `json:"nip"`
	Nidn        string             `json:"nidn"`
	PeriodeType domain.PeriodeType `json:"periode_type"` // CALENDAR / CUTOFF
	PeriodeKey  string             `json:"periode_key"`  // e.g. 2026-07 or 2026-07-CUTOFF
}

type GetSummaryReportQueryHandler struct {
	repo domain.IReportRepository
}

func NewGetSummaryReportQueryHandler(repo domain.IReportRepository) *GetSummaryReportQueryHandler {
	return &GetSummaryReportQueryHandler{repo: repo}
}

func (h *GetSummaryReportQueryHandler) Handle(ctx context.Context, query *GetSummaryReportQuery) (common.ResultValue[*domain.RekapLaporanBulanan], error) {
	summary, err := h.repo.GetReportSummary(ctx, query.Nip, query.PeriodeType, query.PeriodeKey)
	if err != nil || summary == nil {
		return common.FailureValue[*domain.RekapLaporanBulanan](domain.ReportNotFound()), nil
	}
	return common.SuccessValue(summary), nil
}
