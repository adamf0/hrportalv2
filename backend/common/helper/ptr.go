package helper

func StrPtr(s string) *string {
	return &s
}

func StringValue(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func IntPtr(i int) *int {
	return &i
}

func IntValue(i *int) int {
	if i == nil {
		return 0
	}
	return *i
}
