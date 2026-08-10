package utils

import (
	"math"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

// PaginationMeta represents pagination response metadata
type PaginationMeta struct {
	Page        int   `json:"page"`
	Limit       int   `json:"limit"`
	TotalItems  int64 `json:"totalItems"`
	TotalPages  int   `json:"totalPages"`
	HasNextPage bool  `json:"hasNextPage"`
	HasPrevPage bool  `json:"hasPrevPage"`
}

// GetPaginationParams extracts page and limit from query parameters
func GetPaginationParams(c *fiber.Ctx) (page int, limit int) {
	page, _ = strconv.Atoi(c.Query("page", "1"))
	if page < 1 {
		page = 1
	}

	limit, _ = strconv.Atoi(c.Query("limit", c.Query("pageSize", c.Query("per_page", "10"))))
	if limit < 1 {
		limit = 10
	} else if limit > 100 {
		limit = 100
	}

	return page, limit
}

// BuildPaginationMeta constructs PaginationMeta given total count, page, and limit
func BuildPaginationMeta(total int64, page int, limit int) PaginationMeta {
	totalPages := int(math.Ceil(float64(total) / float64(limit)))
	if totalPages < 0 {
		totalPages = 0
	}

	return PaginationMeta{
		Page:        page,
		Limit:       limit,
		TotalItems:  total,
		TotalPages:  totalPages,
		HasNextPage: page < totalPages,
		HasPrevPage: page > 1,
	}
}
