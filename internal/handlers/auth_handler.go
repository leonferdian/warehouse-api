package handlers

import (
	"warehouse-api/internal/models"
	"warehouse-api/internal/utils"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct{}

func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body")
		return
	}

	// Hardcoded credentials for testing
	if req.Username != "admin" || req.Password != "admin123" {
		utils.UnauthorizedResponse(c, "Invalid credentials")
		return
	}

	token, err := utils.GenerateToken(req.Username)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to generate token", err)
		return
	}

	expiresAt := utils.GetExpirationTime().Format("2006-01-02T15:04:05Z07:00")

	response := models.LoginResponse{
		Token:     token,
		ExpiresAt: expiresAt,
	}

	utils.SuccessResponse(c, "Login successful", response)
}

