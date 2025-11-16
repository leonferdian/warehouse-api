package services

import (
	"errors"
	"warehouse-api/internal/models"
	"warehouse-api/internal/repositories"
)

type ProductService struct {
	productRepo *repositories.ProductRepository
}

func NewProductService(productRepo *repositories.ProductRepository) *ProductService {
	return &ProductService{productRepo: productRepo}
}

func (s *ProductService) Create(req *models.CreateProductRequest) (*models.Product, error) {
	// Check if SKU already exists
	existing, err := s.productRepo.GetBySKU(req.SKUName)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("SKU name already exists")
	}

	product := &models.Product{
		SKUName:  req.SKUName,
		Quantity: req.Quantity,
	}

	err = s.productRepo.Create(product)
	if err != nil {
		return nil, err
	}

	return product, nil
}

func (s *ProductService) GetByID(id int) (*models.Product, error) {
	product, err := s.productRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	if product == nil {
		return nil, errors.New("product not found")
	}
	return product, nil
}

func (s *ProductService) GetAll(page, limit int, search string) ([]*models.Product, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	return s.productRepo.GetAll(page, limit, search)
}

func (s *ProductService) Update(id int, req *models.UpdateProductRequest) (*models.Product, error) {
	product, err := s.productRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	if product == nil {
		return nil, errors.New("product not found")
	}

	// Check if SKU name is being changed and if new SKU already exists
	if product.SKUName != req.SKUName {
		existing, err := s.productRepo.GetBySKU(req.SKUName)
		if err != nil {
			return nil, err
		}
		if existing != nil && existing.ID != id {
			return nil, errors.New("SKU name already exists")
		}
	}

	product.SKUName = req.SKUName
	product.Quantity = req.Quantity

	err = s.productRepo.Update(product)
	if err != nil {
		return nil, err
	}

	return product, nil
}

