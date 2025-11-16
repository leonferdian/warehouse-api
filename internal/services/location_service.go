package services

import (
	"errors"
	"warehouse-api/internal/models"
	"warehouse-api/internal/repositories"
)

type LocationService struct {
	locationRepo *repositories.LocationRepository
}

func NewLocationService(locationRepo *repositories.LocationRepository) *LocationService {
	return &LocationService{locationRepo: locationRepo}
}

func (s *LocationService) Create(req *models.CreateLocationRequest) (*models.Location, error) {
	// Check if code already exists
	existing, err := s.locationRepo.GetByCode(req.Code)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("location code already exists")
	}

	location := &models.Location{
		Code:     req.Code,
		Name:     req.Name,
		Capacity: req.Capacity,
	}

	err = s.locationRepo.Create(location)
	if err != nil {
		return nil, err
	}

	return location, nil
}

func (s *LocationService) GetAll() ([]*models.LocationWithUsage, error) {
	return s.locationRepo.GetAll()
}

func (s *LocationService) GetCurrentUsage(locationID int) (int, error) {
	return s.locationRepo.GetCurrentUsage(locationID)
}

