package domain

type Paged[T any] struct {
	Data       []T   `json:"data"`
	TotalCount int64 `json:"total_count"`
	Page       int   `json:"page"`
	PageSize   int   `json:"page_size"`
}

func NewPaged[T any](data []T, totalCount int64, page int, pageSize int) Paged[T] {
	if data == nil {
		data = []T{}
	}
	return Paged[T]{
		Data:       data,
		TotalCount: totalCount,
		Page:       page,
		PageSize:   pageSize,
	}
}
