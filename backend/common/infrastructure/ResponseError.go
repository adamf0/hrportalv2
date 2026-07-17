package infrastructure

import (
	"errors"
	"fmt"
	"runtime"
	"strings"

	"hrportal_backend/common/domain"

	"github.com/gofiber/fiber/v2"
)

type ResponseError struct {
	Code    string      `json:"code"`
	Message interface{} `json:"message"`
	Trace   interface{} `json:"trace,omitempty"`
}

func (e *ResponseError) Error() string {
	switch m := e.Message.(type) {
	case string:
		return m
	default:
		return fmt.Sprintf("%s: %v", e.Code, m)
	}
}

func NewResponseError(code string, message interface{}) *ResponseError {
	return &ResponseError{
		Code:    code,
		Message: message,
		Trace:   getTrace(),
	}
}

func NewInternalError(err error) *ResponseError {
	if err == nil {
		return nil
	}

	return &ResponseError{
		Code:    "INTERNAL_SERVER_ERROR",
		Message: err.Error(),
		Trace:   getTrace(),
	}
}

func mapCodeToStatus(code string) int {
	switch {
	case strings.HasSuffix(code, ".Validation"):
		return 400
	case strings.HasSuffix(code, ".NotFound"):
		return 404
	case strings.HasSuffix(code, ".Conflict"):
		return 409
	default:
		return 400
	}
}

func mapDomainErrorToStatus(errType domain.ErrorType) int {
	switch errType {
	case domain.Validation:
		return 400
	case domain.NotFound:
		return 404
	case domain.Conflict:
		return 409
	default:
		return 500
	}
}

func HandleError(c *fiber.Ctx, err error) error {
	if err == nil {
		return nil
	}

	trace := getTrace()

	var respErr *ResponseError
	if errors.As(err, &respErr) {
		re := &ResponseError{
			Code:    respErr.Code,
			Message: respErr.Message,
			Trace:   trace,
		}
		status := mapCodeToStatus(respErr.Code)
		return c.Status(status).JSON(re)
	}

	var derr domain.Error
	if errors.As(err, &derr) {
		re := &ResponseError{
			Code:    derr.Code,
			Message: derr.Description,
			Trace:   trace,
		}
		status := mapDomainErrorToStatus(derr.Type)
		return c.Status(status).JSON(re)
	}

	return c.Status(500).JSON(NewInternalError(err))
}

func getTrace() string {
	const maxDepth = 10
	pcs := make([]uintptr, maxDepth)
	n := runtime.Callers(3, pcs)
	frames := runtime.CallersFrames(pcs[:n])

	var traceLines []string
	for {
		frame, more := frames.Next()
		traceLines = append(traceLines, fmt.Sprintf("%s:%d %s", frame.File, frame.Line, frame.Function))
		if !more {
			break
		}
	}
	return strings.Join(traceLines, "\n")
}
