package handlers

import (
	"strconv"
	"warehouse-api/internal/models"
	"warehouse-api/internal/services"
	"warehouse-api/internal/utils"

	"github.com/gin-gonic/gin"
)

type ProductHandler struct {
	productService *services.ProductService
}

func NewProductHandler(productService *services.ProductService) *ProductHandler {
	return &ProductHandler{productService: productService}
}

func (h *ProductHandler) GetAll(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	search := c.Query("search")

	products, total, err := h.productService.GetAll(page, limit, search)
	if err != nil {
		utils.InternalServerErrorResponse(c, "Failed to get products", err)
		return
	}

	response := map[string]interface{}{
		"products": products,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	utils.SuccessResponse(c, "Products retrieved successfully", response)
}

func (h *ProductHandler) Create(c *gin.Context) {
	var req models.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: "+err.Error())
		return
	}

	product, err := h.productService.Create(&req)
	if err != nil {
		if err.Error() == "SKU name already exists" {
			utils.BadRequestResponse(c, err.Error())
			return
		}
		utils.InternalServerErrorResponse(c, "Failed to create product", err)
		return
	}

	utils.SuccessResponse(c, "Product created successfully", product)
}

func (h *ProductHandler) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var req models.UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid request body: "+err.Error())
		return
	}

	product, err := h.productService.Update(id, &req)
	if err != nil {
		if err.Error() == "product not found" {
			utils.NotFoundResponse(c, err.Error())
			return
		}
		if err.Error() == "SKU name already exists" {
			utils.BadRequestResponse(c, err.Error())
			return
		}
		utils.InternalServerErrorResponse(c, "Failed to update product", err)
		return
	}

	utils.SuccessResponse(c, "Product updated successfully", product)
}

