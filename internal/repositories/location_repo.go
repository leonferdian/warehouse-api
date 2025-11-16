package repositories

import (
	"database/sql"
	"warehouse-api/internal/models"
)

type LocationRepository struct {
	db *sql.DB
}

func NewLocationRepository(db *sql.DB) *LocationRepository {
	return &LocationRepository{db: db}
}

func (r *LocationRepository) Create(location *models.Location) error {
	query := `
		INSERT INTO locations (code, name, capacity)
		VALUES ($1, $2, $3)
		RETURNING id, created_at
	`
	err := r.db.QueryRow(query, location.Code, location.Name, location.Capacity).Scan(
		&location.ID, &location.CreatedAt,
	)
	return err
}

func (r *LocationRepository) GetByID(id int) (*models.Location, error) {
	location := &models.Location{}
	query := `SELECT id, code, name, capacity, created_at FROM locations WHERE id = $1`
	err := r.db.QueryRow(query, id).Scan(
		&location.ID, &location.Code, &location.Name,
		&location.Capacity, &location.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return location, err
}

func (r *LocationRepository) GetAll() ([]*models.LocationWithUsage, error) {
	query := `
		SELECT 
			l.id, l.code, l.name, l.capacity, l.created_at,
			COALESCE(SUM(CASE WHEN sm.type = 'IN' THEN sm.quantity ELSE -sm.quantity END), 0) as current_usage
		FROM locations l
		LEFT JOIN stock_movements sm ON sm.location_id = l.id
		GROUP BY l.id, l.code, l.name, l.capacity, l.created_at
		ORDER BY l.id
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var locations []*models.LocationWithUsage
	for rows.Next() {
		loc := &models.LocationWithUsage{}
		var usage int
		err := rows.Scan(
			&loc.ID, &loc.Code, &loc.Name, &loc.Capacity, &loc.CreatedAt, &usage,
		)
		if err != nil {
			return nil, err
		}
		loc.CurrentUsage = usage
		if loc.CurrentUsage < 0 {
			loc.CurrentUsage = 0
		}
		loc.Available = loc.Capacity - loc.CurrentUsage
		if loc.Available < 0 {
			loc.Available = 0
		}
		locations = append(locations, loc)
	}

	return locations, nil
}

func (r *LocationRepository) GetCurrentUsage(locationID int) (int, error) {
	query := `
		SELECT COALESCE(SUM(CASE WHEN type = 'IN' THEN quantity ELSE -quantity END), 0)
		FROM stock_movements
		WHERE location_id = $1
	`
	var usage int
	err := r.db.QueryRow(query, locationID).Scan(&usage)
	if err != nil {
		return 0, err
	}
	if usage < 0 {
		usage = 0
	}
	return usage, nil
}

