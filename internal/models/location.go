package models

import "time"

type Location struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Capacity  int       `json:"capacity"`
	CreatedAt time.Time `json:"created_at"`
}

type LocationWithUsage struct {
	Location
	CurrentUsage int `json:"current_usage"`
	Available    int `json:"available"`
}

type CreateLocationRequest struct {
	Code     string `json:"code" binding:"required"`
	Name     string `json:"name" binding:"required"`
	Capacity int    `json:"capacity" binding:"required,gt=0"`
}
