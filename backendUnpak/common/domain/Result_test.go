package domain

import (
	"testing"
)

func TestResultValue(t *testing.T) {
	res := SuccessValue("OK")
	if !res.IsSuccess {
		t.Errorf("expected success")
	}

	val, err := res.GetValue()
	if err != nil || val != "OK" {
		t.Errorf("expected value OK")
	}
}
