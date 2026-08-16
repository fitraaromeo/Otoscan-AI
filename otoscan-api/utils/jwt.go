package utils

import (
	"errors"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWTClaims defines custom JWT claims structure
type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// GetJWTSecret gets the secret key from environment or fallback default
func GetJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "otoscan_secret_jwt_key_2026"
	}
	return []byte(secret)
}

// GetJWTExpiryHours gets the expiry duration in hours from environment
func GetJWTExpiryHours() int {
	hoursStr := os.Getenv("JWT_EXPIRATION_HOURS")
	if hoursStr != "" {
		if hours, err := strconv.Atoi(hoursStr); err == nil && hours > 0 {
			return hours
		}
	}
	return 24 // default 24 hours
}

// GenerateToken creates a signed JWT token with user claims
func GenerateToken(userID string, email string, role string) (string, time.Time, error) {
	expiryHours := GetJWTExpiryHours()
	expirationTime := time.Now().Add(time.Duration(expiryHours) * time.Hour)

	claims := &JWTClaims{
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(GetJWTSecret())
	if err != nil {
		return "", expirationTime, err
	}

	return tokenString, expirationTime, nil
}

// ValidateToken parses and validates a JWT token string
func ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return GetJWTSecret(), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid or expired token")
	}

	return claims, nil
}
