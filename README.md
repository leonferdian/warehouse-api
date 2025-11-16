# Warehouse Management System - REST API

A REST API for warehouse management system built with Go, featuring product management, stock tracking, and location management with JWT authentication.

## Features

- **Product Management**: Create, read, and update products with SKU tracking
- **Stock Movements**: Track stock IN/OUT with business rule validation
- **Location Management**: Manage warehouse locations with capacity tracking
- **JWT Authentication**: Secure API endpoints with JWT tokens
- **PostgreSQL Database**: Using Supabase PostgreSQL database

## Tech Stack

- **Language**: Go 1.21+
- **Framework**: Gin
- **Database**: PostgreSQL (Supabase)
- **Authentication**: JWT
- **No ORM**: Raw SQL with lib/pq

## Project Structure

```
warehouse-api/
├── cmd/
│   └── api/
│       └── main.go                 # Entry point
├── internal/
│   ├── config/                     # Configuration
│   ├── models/                     # Data models
│   ├── repositories/               # Database layer
│   ├── services/                   # Business logic
│   ├── handlers/                   # HTTP handlers
│   ├── middleware/                 # Middleware (auth, logger)
│   └── utils/                      # Utilities (JWT, response)
├── migrations/                     # Database migrations
├── docker/                         # Docker files
├── .env.example                    # Environment variables template
└── go.mod                          # Go modules
```

## Setup

### Prerequisites

- Go 1.21 or higher
- PostgreSQL database (Supabase)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd warehouse-api
```

2. Install dependencies:
```bash
go mod download
```

3. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

4. Update `.env` with your database credentials:
```env
DB_HOST=db.pnlcheslucpptcrwcauf.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=leonferdian@supabase
DB_NAME=postgres
JWT_SECRET=your-secret-key-here
PORT=8080
```

5. Run the application:
```bash
go run cmd/api/main.go 
or 
.\warehouse-api.exe 
```

The server will start on port 8080.

## API Endpoints

### Authentication

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "expires_at": "2024-01-01T12:00:00Z"
  }
}
```

### Products (Protected)

#### Get All Products
```http
GET /api/products?page=1&limit=10&search=sku
Authorization: Bearer <token>
```

#### Create Product
```http
POST /api/products
Authorization: Bearer <token>
Content-Type: application/json

{
  "sku_name": "PROD-001",
  "quantity": 100
}
```

#### Update Product
```http
PUT /api/products/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "sku_name": "PROD-001",
  "quantity": 150
}
```

### Stock Movements (Protected)

#### Create Stock Movement
```http
POST /api/stock-movements
Authorization: Bearer <token>
Content-Type: application/json

{
  "product_id": 1,
  "location_id": 1,
  "type": "IN",
  "quantity": 50
}
```

**Business Rules:**
- **Stock OUT**: Validates that product quantity >= movement quantity
- **Stock IN**: Validates that location capacity is not exceeded
- Automatically updates product quantity

#### Get Stock Movements
```http
GET /api/stock-movements?product_id=1&location_id=2&type=IN&start_date=2024-01-01&end_date=2024-12-31&page=1&limit=10
Authorization: Bearer <token>
```

### Locations (Protected)

#### Get All Locations
```http
GET /api/locations
Authorization: Bearer <token>
```

**Response includes:**
- Location details
- Current usage
- Available capacity

## Testing with cURL

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```
or 

```powershell
$body = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

### Create Product
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"sku_name":"PROD-001","quantity":100}'
```

or

```powershell
$productData = @{
    sku_name = "TEST-SKU-001"
    quantity = 100
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/products" -Method Post -Headers $headers -Body $productData
```

### Get All Products

```powershell
# Get first page with 10 items
Invoke-RestMethod -Uri "http://localhost:8080/api/products?page=1&limit=10" -Method Get -Headers $headers

# Search for products
Invoke-RestMethod -Uri "http://localhost:8080/api/products?search=TEST" -Method Get -Headers $headers
```
### Update a Product
```powershell
# Replace :id with the actual product ID
$updateData = @{
    sku_name = "UPDATED-SKU-001"
    quantity = 50
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/products/1" -Method Put -Headers $headers -Body $updateData
```

### Stock Movement (IN)
```bash
curl -X POST http://localhost:8080/api/stock-movements \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"location_id":1,"type":"IN","quantity":50}'
```
or 

```powershell
$movementData = @{
    product_id = 1  # Replace with actual product ID
    location_id = 1 # Replace with actual location ID
    type = "IN"
    quantity = 10
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements" -Method Post -Headers $headers -Body $movementData
```
### Stock Movement (OUT)
```bash
curl -X POST http://localhost:8080/api/stock-movements \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"location_id":1,"type":"OUT","quantity":20}'
```
or

```powershell
$movementData = @{
    product_id = 1  # Replace with actual product ID
    location_id = 1 # Replace with actual location ID
    type = "OUT"
    quantity = 5
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements" -Method Post -Headers $headers -Body $movementData
```

### Get All Stock Movements
```powershell
# Get all movements
Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements" -Method Get -Headers $headers

# Filter by product
Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements?product_id=1" -Method Get -Headers $headers

# Filter by type (IN/OUT)
Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements?type=IN" -Method Get -Headers $headers

# Filter by date range (YYYY-MM-DD)
Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements?start_date=2025-11-01&end_date=2025-11-30" -Method Get -Headers $headers

# Pagination
Invoke-RestMethod -Uri "http://localhost:8080/api/stock-movements?page=1&limit=5" -Method Get -Headers $headers
```

## Locations
### Create a New Location
```powershell
# Create a new location
$locationData = @{
    code = "WH-001"
    name = "Main Warehouse"
    capacity = 1000
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/locations" -Method Post -Headers $headers -Body $locationData
```

### Get All Locations
```powershell
# Get all locations
Invoke-RestMethod -Uri "http://localhost:8080/api/locations" -Method Get -Headers $headers

# With pagination
Invoke-RestMethod -Uri "http://localhost:8080/api/locations?page=1&limit=5" -Method Get -Headers $headers

# Search by name
Invoke-RestMethod -Uri "http://localhost:8080/api/locations?search=Main" -Method Get -Headers $headers
```

## Docker

### Build and Run with Docker

```bash
# Build the image
docker build -f docker/Dockerfile -t warehouse-api .

# Run the container
docker run -p 8080:8080 --env-file .env warehouse-api
```

### Docker Compose

```bash
cd docker
docker-compose up -d
```

## Database Schema

### Products
- `id`: Primary key
- `sku_name`: Unique SKU identifier
- `quantity`: Current stock quantity
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### Locations
- `id`: Primary key
- `code`: Unique location code
- `name`: Location name
- `capacity`: Maximum capacity
- `created_at`: Creation timestamp

### Stock Movements
- `id`: Primary key
- `product_id`: Foreign key to products
- `location_id`: Foreign key to locations
- `type`: 'IN' or 'OUT'
- `quantity`: Movement quantity
- `created_at`: Creation timestamp

## Business Rules

1. **Stock OUT Validation**: Before creating a stock OUT movement, the system validates that the product has sufficient quantity.

2. **Stock IN Validation**: Before creating a stock IN movement, the system validates that the location has available capacity.

3. **Auto-Update Product Quantity**: Product quantity is automatically updated when stock movements are created, using database transactions for consistency.

4. **Authentication**: All endpoints except `/api/auth/login` require a valid JWT token in the Authorization header.

## Error Response Format

```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error description"
}
```

## Success Response Format

```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

## License

MIT License

