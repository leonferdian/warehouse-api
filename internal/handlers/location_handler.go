package handlers

import (
	"warehouse-api/internal/models"
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

func (h *LocationHandler) Create(c *gin.Context) {
	var req models.CreateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: "+err.Error())
		return
	}

	location, err := h.locationService.Create(&req)
	if err != nil {
		if err.Error() == "location code already exists" {
			utils.BadRequestResponse(c, err.Error())
			return
		}
		utils.InternalServerErrorResponse(c, "Failed to create location", err)
		return
	}

	utils.SuccessResponse(c, "Location created successfully", location)
}

