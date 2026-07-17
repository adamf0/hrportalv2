package domain

import (
	"errors"
	"fmt"
)

type Result struct {
	IsSuccess bool
	Error     Error
}

func Success() Result {
	return Result{IsSuccess: true, Error: None}
}

func Failure(err Error) Result {
	return Result{IsSuccess: false, Error: err}
}

type ResultValue[T any] struct {
	Result
	Value T
}

func SuccessValue[T any](value T) ResultValue[T] {
	return ResultValue[T]{Result: Success(), Value: value}
}

func FailureValue[T any](err Error) ResultValue[T] {
	var zero T
	return ResultValue[T]{Result: Failure(err), Value: zero}
}

func (r ResultValue[T]) GetValue() (T, error) {
	if !r.IsSuccess {
		var zero T
		return zero, errors.New(fmt.Sprintf("Cannot get value of failed result: %v", r.Error.Description))
	}
	return r.Value, nil
}
