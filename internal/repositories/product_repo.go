package repositories

import (
	"database/sql"
	"warehouse-api/internal/models"
)

type ProductRepository struct {
	db *sql.DB
}

func NewProductRepository(db *sql.DB) *ProductRepository {
	return &ProductRepository{db: db}
}

func (r *ProductRepository) Create(product *models.Product) error {
	query := `
		INSERT INTO products (sku_name, quantity)
		VALUES ($1, $2)
		RETURNING id, created_at, updated_at
	`
	err := r.db.QueryRow(query, product.SKUName, product.Quantity).Scan(
		&product.ID, &product.CreatedAt, &product.UpdatedAt,
	)
	return err
}

func (r *ProductRepository) GetByID(id int) (*models.Product, error) {
	product := &models.Product{}
	query := `SELECT id, sku_name, quantity, created_at, updated_at FROM products WHERE id = $1`
	err := r.db.QueryRow(query, id).Scan(
		&product.ID, &product.SKUName, &product.Quantity,
		&product.CreatedAt, &product.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return product, err
}

func (r *ProductRepository) GetBySKU(skuName string) (*models.Product, error) {
	product := &models.Product{}
	query := `SELECT id, sku_name, quantity, created_at, updated_at FROM products WHERE sku_name = $1`
	err := r.db.QueryRow(query, skuName).Scan(
		&product.ID, &product.SKUName, &product.Quantity,
		&product.CreatedAt, &product.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return product, err
}

func (r *ProductRepository) GetAll(page, limit int, search string) ([]*models.Product, int, error) {
	offset := (page - 1) * limit
	var products []*models.Product
	var total int

	// Count total
	countQuery := `SELECT COUNT(*) FROM products`
	if search != "" {
		countQuery += ` WHERE sku_name ILIKE $1`
		err := r.db.QueryRow(countQuery, "%"+search+"%").Scan(&total)
		if err != nil {
			return nil, 0, err
		}
	} else {
		err := r.db.QueryRow(countQuery).Scan(&total)
		if err != nil {
			return nil, 0, err
		}
	}

	// Get products
	query := `SELECT id, sku_name, quantity, created_at, updated_at FROM products`
	if search != "" {
		query += ` WHERE sku_name ILIKE $1`
		query += ` ORDER BY id DESC LIMIT $2 OFFSET $3`
		rows, err := r.db.Query(query, "%"+search+"%", limit, offset)
		if err != nil {
			return nil, 0, err
		}
		defer rows.Close()

		for rows.Next() {
			product := &models.Product{}
			err := rows.Scan(&product.ID, &product.SKUName, &product.Quantity,
				&product.CreatedAt, &product.UpdatedAt)
			if err != nil {
				return nil, 0, err
			}
			products = append(products, product)
		}
	} else {
		query += ` ORDER BY id DESC LIMIT $1 OFFSET $2`
		rows, err := r.db.Query(query, limit, offset)
		if err != nil {
			return nil, 0, err
		}
		defer rows.Close()

		for rows.Next() {
			product := &models.Product{}
			err := rows.Scan(&product.ID, &product.SKUName, &product.Quantity,
				&product.CreatedAt, &product.UpdatedAt)
			if err != nil {
				return nil, 0, err
			}
			products = append(products, product)
		}
	}

	return products, total, nil
}

func (r *ProductRepository) Update(product *models.Product) error {
	query := `
		UPDATE products
		SET sku_name = $1, quantity = $2, updated_at = CURRENT_TIMESTAMP
		WHERE id = $3
		RETURNING updated_at
	`
	err := r.db.QueryRow(query, product.SKUName, product.Quantity, product.ID).Scan(&product.UpdatedAt)
	return err
}

func (r *ProductRepository) UpdateQuantity(id int, quantity int) error {
	query := `UPDATE products SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	_, err := r.db.Exec(query, quantity, id)
	return err
}

