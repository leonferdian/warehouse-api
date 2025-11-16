warehouse-api/
├── cmd/
│   └── api/
│       └── main.go                 # Entry point aplikasi
├── internal/
│   ├── config/
│   │   └── config.go              # Konfigurasi database & environment
│   ├── models/
│   │   ├── product.go             # Model Product
│   │   ├── location.go            # Model Location
│   │   └── stock_movement.go     # Model Stock Movement
│   ├── repositories/
│   │   ├── product_repo.go        # Database layer untuk Product
│   │   ├── location_repo.go       # Database layer untuk Location
│   │   └── stock_movement_repo.go # Database layer untuk Stock Movement
│   ├── services/
│   │   ├── product_service.go     # Business logic Product
│   │   ├── location_service.go    # Business logic Location
│   │   └── stock_service.go       # Business logic Stock Movement
│   ├── handlers/
│   │   ├── auth_handler.go        # Handler authentication
│   │   ├── product_handler.go     # Handler Product endpoints
│   │   ├── location_handler.go    # Handler Location endpoints
│   │   └── stock_handler.go       # Handler Stock Movement endpoints
│   ├── middleware/
│   │   ├── auth.go                # JWT authentication middleware
│   │   └── logger.go              # Logging middleware
│   └── utils/
│       ├── response.go            # Standard API response
│       ├── jwt.go                 # JWT token utilities
│       └── validator.go           # Request validation
├── migrations/
│   └── schema.sql                 # Database schema
├── docker/
│   ├── Dockerfile                 # Docker image configuration
│   └── docker-compose.yml         # Docker compose setup
├── .env.example                   # Environment variables template
├── go.mod                         # Go modules
└── README.md                      # Documentation