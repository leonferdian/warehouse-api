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

