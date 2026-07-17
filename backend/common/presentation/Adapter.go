package presentation

import (
	"bufio"
	"encoding/json"
	"fmt"

	commondomain "hrportal_backend/common/domain"

	"github.com/bytedance/sonic"
	"github.com/gofiber/fiber/v2"
)

type OutputAdapter[T any] interface {
	Send(c *fiber.Ctx, data commondomain.Paged[T]) error
}

type PagingAdapter[T any] struct{}

func (a *PagingAdapter[T]) Send(c *fiber.Ctx, data commondomain.Paged[T]) error {
	return c.JSON(data)
}

type AllAdapter[T any] struct{}

func (a *AllAdapter[T]) Send(c *fiber.Ctx, data commondomain.Paged[T]) error {
	return c.JSON(data.Data)
}

type NDJSONAdapter[T any] struct{}

func (a *NDJSONAdapter[T]) Send(c *fiber.Ctx, data commondomain.Paged[T]) error {
	c.Set("Content-Type", "application/x-ndjson")

	for _, u := range data.Data {
		b, _ := json.Marshal(u)
		fmt.Fprintln(c, string(b))
	}

	return nil
}

type SSEAdapter[T any] struct{}

func (a *SSEAdapter[T]) Send(c *fiber.Ctx, data commondomain.Paged[T]) error {
	c.Set("Content-Type", "text/event-stream")
	c.Set("Cache-Control", "no-cache")
	c.Set("Connection", "keep-alive")

	w := bufio.NewWriterSize(c.Response().BodyWriter(), 256*1024)
	totalCount := len(data.Data)

	fmt.Fprintf(w, "total: %d\n\n", totalCount)
	_ = w.Flush()

	_, _ = w.WriteString("event: start\n\n")
	_ = w.Flush()

	var jsonEngine = sonic.ConfigFastest
	enc := jsonEngine.NewEncoder(w)

	for i, u := range data.Data {
		_, _ = w.WriteString("data: ")
		_ = enc.Encode(u)
		_ = w.WriteByte('\n')

		if i%100 == 0 {
			_ = w.Flush()
		}
	}

	_, _ = w.WriteString("event: done\n\n")
	_ = w.Flush()

	return nil
}
