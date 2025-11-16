package services

import (
	"database/sql"
	"errors"
	"warehouse-api/internal/models"
	"warehouse-api/internal/repositories"
)

type StockService struct {
	stockRepo    *repositories.StockMovementRepository
	productRepo  *repositories.ProductRepository
	locationRepo *repositories.LocationRepository
	db           *sql.DB
}

func NewStockService(
	stockRepo *repositories.StockMovementRepository,
	productRepo *repositories.ProductRepository,
	locationRepo *repositories.LocationRepository,
	db *sql.DB,
) *StockService {
	return &StockService{
		stockRepo:    stockRepo,
		productRepo:  productRepo,
		locationRepo: locationRepo,
		db:           db,
	}
}

func (s *StockService) Create(req *models.CreateStockMovementRequest) (*models.StockMovement, error) {
	// Validate product exists
	product, err := s.productRepo.GetByID(req.ProductID)
	if err != nil {
		return nil, err
	}
	if product == nil {
		return nil, errors.New("product not found")
	}

	// Validate location exists
	location, err := s.locationRepo.GetByID(req.LocationID)
	if err != nil {
		return nil, err
	}
	if location == nil {
		return nil, errors.New("location not found")
	}

	// Start transaction
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Business rules validation
	if req.Type == "OUT" {
		// Check if product has enough quantity
		if product.Quantity < req.Quantity {
			return nil, errors.New("insufficient product quantity")
		}
		// Update product quantity
		newQuantity := product.Quantity - req.Quantity
		_, err = tx.Exec("UPDATE products SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", newQuantity, req.ProductID)
		if err != nil {
			return nil, err
		}
	} else if req.Type == "IN" {
		// Check location capacity
		currentUsage, err := s.locationRepo.GetCurrentUsage(req.LocationID)
		if err != nil {
			return nil, err
		}
		if currentUsage+req.Quantity > location.Capacity {
			return nil, errors.New("location capacity exceeded")
		}
		// Update product quantity
		newQuantity := product.Quantity + req.Quantity
		_, err = tx.Exec("UPDATE products SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", newQuantity, req.ProductID)
		if err != nil {
			return nil, err
		}
	}

	// Create stock movement
	movement := &models.StockMovement{
		ProductID:  req.ProductID,
		LocationID: req.LocationID,
		Type:       req.Type,
		Quantity:   req.Quantity,
	}

	query := `
		INSERT INTO stock_movements (product_id, location_id, type, quantity)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`
	err = tx.QueryRow(query, movement.ProductID, movement.LocationID, movement.Type, movement.Quantity).Scan(
		&movement.ID, &movement.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		return nil, err
	}

	return movement, nil
}

func (s *StockService) GetAll(filter *models.StockMovementFilter) ([]*models.StockMovement, int, error) {
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.Limit < 1 {
		filter.Limit = 10
	}
	return s.stockRepo.GetAll(filter)
}

