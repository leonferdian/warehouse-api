package models

import "time"

type Product struct {
	ID        int       `json:"id"`
	SKUName   string    `json:"sku_name"`
	Quantity  int       `json:"quantity"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CreateProductRequest struct {
	SKUName  string `json:"sku_name" binding:"required"`
	Quantity int    `json:"quantity" binding:"gte=0"`
}

type UpdateProductRequest struct {
	SKUName  string `json:"sku_name" binding:"required"`
	Quantity int    `json:"quantity" binding:"gte=0"`
}

