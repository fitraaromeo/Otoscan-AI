package utils

import (
	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes a plain text password using bcrypt
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPasswordHash compares a plain text password with a bcrypt hash, or falls back to plain text comparison
func CheckPasswordHash(password, hash string) bool {
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)); err == nil {
		return true
	}
	// Fallback for legacy plain-text passwords in database
	return hash != "" && hash == password
}
