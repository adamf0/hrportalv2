package domain

import (
	"fmt"
)

type ErrorType int

const (
	ErrorFailure ErrorType = iota
	Validation
	Problem
	NotFound
	Conflict
)

type Error struct {
	Code        string
	Description string
	Type        ErrorType
}

func (e Error) Error() string {
	return fmt.Sprintf("%s: %s", e.Code, e.Description)
}

var None = Error{"", "", ErrorFailure}
var NullValue = Error{"General.Null", "Null value was provided", ErrorFailure}

func FailureError(code, description string) Error {
	return Error{code, description, ErrorFailure}
}

func NotFoundError(code, description string) Error {
	return Error{code, description, NotFound}
}

func ProblemError(code, description string) Error {
	return Error{code, description, Problem}
}

func ConflictError(code, description string) Error {
	return Error{code, description, Conflict}
}
