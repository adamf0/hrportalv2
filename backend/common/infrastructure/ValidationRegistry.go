package infrastructure

import (
	"reflect"
	"strings"

	validation "github.com/go-ozzo/ozzo-validation/v4"
)

type validatorEntry struct {
	fn    func(interface{}) error
	label string
}

var validationRegistry = map[reflect.Type]validatorEntry{}

func RegisterValidation[T any](fn func(T) error, label string) {
	var zero T

	validationRegistry[reflect.TypeOf(zero)] = validatorEntry{
		label: label,
		fn: func(req interface{}) error {
			return fn(req.(T))
		},
	}
}

func GetValidator(request interface{}) (validatorEntry, bool) {
	entry, ok := validationRegistry[reflect.TypeOf(request)]
	return entry, ok
}

func Validate(request interface{}) error {
	if entry, ok := GetValidator(request); ok {
		if err := entry.fn(request); err != nil {
			return wrapValidationError(entry.label, err)
		}
	}
	return nil
}

func wrapValidationError(code string, err error) error {
	if ve, ok := err.(validation.Errors); ok {
		msgs := make(map[string]string)
		for field, ferr := range ve {
			key := strings.ToLower(field)
			msgs[key] = ferr.Error()
		}
		return NewResponseError(code, msgs)
	}
	return NewResponseError(code, err.Error())
}
