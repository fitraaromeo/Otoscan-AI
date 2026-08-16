package middleware

import (
	"strings"

	"otoscan-api/utils"

	"github.com/gofiber/fiber/v2"
)

// Protected enforces valid JWT Bearer token authentication
func Protected() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: Missing Authorization header",
			})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: Invalid Authorization format. Format must be 'Bearer <token>'",
			})
		}

		tokenString := parts[1]
		claims, err := utils.ValidateToken(tokenString)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: " + err.Error(),
			})
		}

		// Store parsed claims in Fiber context locals
		c.Locals("user_id", claims.UserID)
		c.Locals("email", claims.Email)
		c.Locals("role", claims.Role)

		return c.Next()
	}
}

// RequireRole restricts endpoint access to specified roles (e.g. "admin", "inspector", "user")
func RequireRole(allowedRoles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userRole, ok := c.Locals("role").(string)
		if !ok || userRole == "" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"status":  "error",
				"message": "Forbidden: Role information missing from context",
			})
		}

		for _, role := range allowedRoles {
			if strings.EqualFold(role, userRole) {
				return c.Next()
			}
		}

		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"status":  "error",
			"message": "Forbidden: You do not have permission to access this resource",
		})
	}
}
