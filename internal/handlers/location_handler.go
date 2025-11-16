package handlers

import (
	"warehouse-api/internal/services"
	"warehouse-api/internal/utils"

	"github.com/gin-gonic/gin"
)

type LocationHandler struct {
	locationService *services.LocationService
}

func NewLocationHandler(locationService *services.LocationService) *LocationHandler {
	return &LocationHandler{locationService: locationService}
}

func (h *LocationHandler) GetAll(c *gin.Context) {
	locations, err := h.locationService.GetAll()
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to get locations", err)
		return
	}

	utils.SuccessResponse(c, "Locations retrieved successfully", locations)
}

