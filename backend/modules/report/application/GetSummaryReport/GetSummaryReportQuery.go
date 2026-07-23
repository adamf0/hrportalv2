package GetSummaryReport

import (
	"context"
	"time"

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
	targetNip := query.Nip
	if targetNip == "" {
		targetNip = query.Nidn
	}

	summary, err := h.repo.GetReportSummary(ctx, targetNip, query.PeriodeType, query.PeriodeKey)
	if err != nil || summary == nil {
		now := time.Now()
		summary = &domain.RekapLaporanBulanan{
			Nip:          targetNip,
			Nidn:         targetNip,
			PeriodeType:  query.PeriodeType,
			PeriodeKey:   query.PeriodeKey,
			TotalMasuk:   0,
			TotalIzin:    0,
			TotalCuti:    0,
			TotalSppd:    0,
			TotalUpacara: 0,
			UpdatedAt:    &now,
		}
	}
	return common.SuccessValue(summary), nil
}
