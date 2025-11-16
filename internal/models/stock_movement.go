package models

import "time"

type StockMovement struct {
	ID         int       `json:"id"`
	ProductID  int       `json:"product_id"`
	LocationID int       `json:"location_id"`
	Type       string    `json:"type"` // IN or OUT
	Quantity   int       `json:"quantity"`
	CreatedAt  time.Time `json:"created_at"`
}

type CreateStockMovementRequest struct {
	ProductID  int    `json:"product_id" binding:"required"`
	LocationID int    `json:"location_id" binding:"required"`
	Type       string `json:"type" binding:"required,oneof=IN OUT"`
	Quantity   int    `json:"quantity" binding:"required,gt=0"`
}

type StockMovementFilter struct {
	ProductID  *int    `form:"product_id"`
	LocationID *int    `form:"location_id"`
	Type       *string `form:"type"`
	StartDate  *string `form:"start_date"`
	EndDate    *string `form:"end_date"`
	Page       int     `form:"page,default=1"`
	Limit      int     `form:"limit,default=10"`
}

