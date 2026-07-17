package domain

import (
	"context"
)

type ICalendarRepository interface {
	GetCalendarEvents(ctx context.Context, nip string, nidn string, startDate string, endDate string) ([]CalendarItem, error)
}
