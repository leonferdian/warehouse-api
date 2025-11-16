package main

import (
	"database/sql"
	"fmt"
	"log"
	"warehouse-api/internal/config"
	"warehouse-api/internal/handlers"
	"warehouse-api/internal/middleware"
	"warehouse-api/internal/repositories"
	"warehouse-api/internal/services"
	"warehouse-api/internal/utils"

	"github.com/gin-gonic/gin"
)

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}

	// Initialize JWT
	utils.InitJWT(cfg.JWTSecret)

	// Connect to database
	db, err := config.ConnectDB(cfg)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Run migrations
	if err := runMigrations(db); err != nil {
		log.Fatal("Failed to run migrations:", err)
	}

	// Initialize repositories
	productRepo := repositories.NewProductRepository(db)
	locationRepo := repositories.NewLocationRepository(db)
	stockRepo := repositories.NewStockMovementRepository(db)

	// Initialize services
	productService := services.NewProductService(productRepo)
	locationService := services.NewLocationService(locationRepo)
	stockService := services.NewStockService(stockRepo, productRepo, locationRepo, db)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler()
	productHandler := handlers.NewProductHandler(productService)
	locationHandler := handlers.NewLocationHandler(locationService)
	stockHandler := handlers.NewStockHandler(stockService)

	// Setup router
	router := gin.Default()

	// Middleware
	router.Use(middleware.LoggerMiddleware())
	router.Use(gin.Recovery())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Public routes
	api := router.Group("/api")
	{
		api.POST("/auth/login", authHandler.Login)
	}

	// Protected routes
	protected := api.Group("")
	protected.Use(middleware.AuthMiddleware())
	{
		// Products
		protected.GET("/products", productHandler.GetAll)
		protected.POST("/products", productHandler.Create)
		protected.PUT("/products/:id", productHandler.Update)

		// Locations
		protected.GET("/locations", locationHandler.GetAll)

		// Stock Movements
		protected.POST("/stock-movements", stockHandler.Create)
		protected.GET("/stock-movements", stockHandler.GetAll)
	}

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Server starting on port %s", cfg.Port)
	if err := router.Run(addr); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func runMigrations(db *sql.DB) error {
	schema := `
		CREATE TABLE IF NOT EXISTS products (
			id SERIAL PRIMARY KEY,
			sku_name VARCHAR(100) NOT NULL UNIQUE,
			quantity INTEGER NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);

		CREATE TABLE IF NOT EXISTS locations (
			id SERIAL PRIMARY KEY,
			code VARCHAR(50) NOT NULL UNIQUE,
			name VARCHAR(100) NOT NULL,
			capacity INTEGER NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);

		CREATE TABLE IF NOT EXISTS stock_movements (
			id SERIAL PRIMARY KEY,
			product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
			location_id INTEGER REFERENCES locations(id) ON DELETE CASCADE,
			type VARCHAR(10) CHECK (type IN ('IN', 'OUT')) NOT NULL,
			quantity INTEGER NOT NULL CHECK (quantity > 0),
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);

		CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON stock_movements(product_id);
		CREATE INDEX IF NOT EXISTS idx_stock_movements_location_id ON stock_movements(location_id);
		CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at ON stock_movements(created_at);
	`

	_, err := db.Exec(schema)
	return err
}

