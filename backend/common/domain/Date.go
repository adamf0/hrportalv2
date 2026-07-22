package domain

import "strings"

// FormatDateOnly ensures date strings sent to MySQL/MariaDB DATE columns are formatted as YYYY-MM-DD
func FormatDateOnly(d string) string {
	if d == "" {
		return ""
	}
	if idx := strings.IndexAny(d, "T "); idx != -1 {
		return d[:idx]
	}
	return d
}
