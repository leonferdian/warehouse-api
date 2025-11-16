package services

import (
	"warehouse-api/internal/models"
	"warehouse-api/internal/repositories"
)

type LocationService struct {
	locationRepo *repositories.LocationRepository
}

func NewLocationService(locationRepo *repositories.LocationRepository) *LocationService {
	return &LocationService{locationRepo: locationRepo}
}

func (s *LocationService) GetAll() ([]*models.LocationWithUsage, error) {
	return s.locationRepo.GetAll()
}

func (s *LocationService) GetCurrentUsage(locationID int) (int, error) {
	return s.locationRepo.GetCurrentUsage(locationID)
}

