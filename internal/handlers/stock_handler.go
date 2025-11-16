package handlers

import (
	"strconv"
	"warehouse-api/internal/models"
	"warehouse-api/internal/services"
	"warehouse-api/internal/utils"

	"github.com/gin-gonic/gin"
)

type StockHandler struct {
	stockService *services.StockService
}

func NewStockHandler(stockService *services.StockService) *StockHandler {
	return &StockHandler{stockService: stockService}
}

func (h *StockHandler) Create(c *gin.Context) {
	var req models.CreateStockMovementRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: "+err.Error())
		return
	}

	movement, err := h.stockService.Create(&req)
	if err != nil {
		if err.Error() == "product not found" || err.Error() == "location not found" {
			utils.NotFoundResponse(c, err.Error())
			return
		}
		if err.Error() == "insufficient product quantity" || err.Error() == "location capacity exceeded" {
			utils.BadRequestResponse(c, err.Error())
			return
		}
		utils.InternalServerErrorResponse(c, "Failed to create stock movement", err)
		return
	}

	utils.SuccessResponse(c, "Stock movement created successfully", movement)
}

func (h *StockHandler) GetAll(c *gin.Context) {
	filter := &models.StockMovementFilter{}

	if productIDStr := c.Query("product_id"); productIDStr != "" {
		if productID, err := strconv.Atoi(productIDStr); err == nil {
			filter.ProductID = &productID
		}
	}

	if locationIDStr := c.Query("location_id"); locationIDStr != "" {
		if locationID, err := strconv.Atoi(locationIDStr); err == nil {
			filter.LocationID = &locationID
		}
	}

	if typeStr := c.Query("type"); typeStr != "" {
		filter.Type = &typeStr
	}

	if startDate := c.Query("start_date"); startDate != "" {
		filter.StartDate = &startDate
	}

	if endDate := c.Query("end_date"); endDate != "" {
		filter.EndDate = &endDate
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	filter.Page = page
	filter.Limit = limit

	movements, total, err := h.stockService.GetAll(filter)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to get stock movements", err)
		return
	}

	response := map[string]interface{}{
		"movements": movements,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	utils.SuccessResponse(c, "Stock movements retrieved successfully", response)
}

