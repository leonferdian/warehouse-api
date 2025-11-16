package repositories

import (
	"database/sql"
	"fmt"
	"warehouse-api/internal/models"
)

type StockMovementRepository struct {
	db *sql.DB
}

func NewStockMovementRepository(db *sql.DB) *StockMovementRepository {
	return &StockMovementRepository{db: db}
}

func (r *StockMovementRepository) Create(movement *models.StockMovement) error {
	query := `
		INSERT INTO stock_movements (product_id, location_id, type, quantity)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`
	err := r.db.QueryRow(query, movement.ProductID, movement.LocationID, movement.Type, movement.Quantity).Scan(
		&movement.ID, &movement.CreatedAt,
	)
	return err
}

func (r *StockMovementRepository) GetAll(filter *models.StockMovementFilter) ([]*models.StockMovement, int, error) {
	var movements []*models.StockMovement
	var total int

	// Build WHERE clause
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIndex := 1

	if filter.ProductID != nil {
		whereClause += ` AND product_id = $` + fmt.Sprintf("%d", argIndex)
		args = append(args, *filter.ProductID)
		argIndex++
	}
	if filter.LocationID != nil {
		whereClause += ` AND location_id = $` + fmt.Sprintf("%d", argIndex)
		args = append(args, *filter.LocationID)
		argIndex++
	}
	if filter.Type != nil {
		whereClause += ` AND type = $` + fmt.Sprintf("%d", argIndex)
		args = append(args, *filter.Type)
		argIndex++
	}
	if filter.StartDate != nil {
		whereClause += ` AND created_at >= $` + fmt.Sprintf("%d", argIndex)
		args = append(args, *filter.StartDate)
		argIndex++
	}
	if filter.EndDate != nil {
		whereClause += ` AND created_at <= $` + fmt.Sprintf("%d", argIndex)
		args = append(args, *filter.EndDate)
		argIndex++
	}

	// Count total
	countQuery := `SELECT COUNT(*) FROM stock_movements ` + whereClause
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get movements
	offset := (filter.Page - 1) * filter.Limit
	limitArgs := []interface{}{}
	limitArgs = append(limitArgs, args...)
	limitArgs = append(limitArgs, filter.Limit, offset)
	
	query := `SELECT id, product_id, location_id, type, quantity, created_at 
			  FROM stock_movements ` + whereClause + ` ORDER BY created_at DESC LIMIT $` + fmt.Sprintf("%d", argIndex) + ` OFFSET $` + fmt.Sprintf("%d", argIndex+1)

	rows, err := r.db.Query(query, limitArgs...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	for rows.Next() {
		movement := &models.StockMovement{}
		err := rows.Scan(
			&movement.ID, &movement.ProductID, &movement.LocationID,
			&movement.Type, &movement.Quantity, &movement.CreatedAt,
		)
		if err != nil {
			return nil, 0, err
			}
		movements = append(movements, movement)
	}

	return movements, total, nil
}

func (r *StockMovementRepository) BeginTx() (*sql.Tx, error) {
	return r.db.Begin()
}

