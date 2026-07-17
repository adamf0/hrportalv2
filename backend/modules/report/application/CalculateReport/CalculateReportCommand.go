package CalculateReport

import (
	"context"

	common "hrportal_backend/common/domain"
	"hrportal_backend/modules/report/domain"
)

type CalculateReportCommand struct {
}

type CalculateReportCommandHandler struct {
	repo domain.IReportRepository
}

func NewCalculateReportCommandHandler(repo domain.IReportRepository) *CalculateReportCommandHandler {
	return &CalculateReportCommandHandler{repo: repo}
}

func (h *CalculateReportCommandHandler) Handle(ctx context.Context, cmd *CalculateReportCommand) (common.ResultValue[map[string]interface{}], error) {
	result, err := h.repo.CalculateReport(ctx)
	if err != nil {
		return common.FailureValue[map[string]interface{}](domain.ReportNotFound()), err
	}
	return common.SuccessValue(result), nil
}
