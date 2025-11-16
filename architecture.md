# Warehouse Management System - REST API Implementation

## Project Overview
Buat REST API untuk sistem manajemen gudang menggunakan Golang dengan fitur:
- Manajemen produk dan stok
- Pelacakan pergerakan stok (IN/OUT)
- Manajemen lokasi gudang
- Autentikasi JWT

**Durasi:** 2 jam
**Database:** PostgreSQL (Supabase)

---

## Tech Stack Requirements

### Backend
- **Language:** Go 1.21+
- **Framework:** Gin atau Fiber (pilih yang paling efisien)
- **Database:** PostgreSQL via Supabase
- **Authentication:** JWT
- **No ORM** - Gunakan database/sql dengan lib/pq atau pgx
- **Docker Ready**

### Database Connection
```
Host: db.pnlcheslucpptcrwcauf.supabase.co
Port: 5432
Database: postgres
User: postgres
Password: leonferdian@supabase
```

---

## Database Schema

### Table: products
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku_name VARCHAR(100) NOT NULL UNIQUE,
    quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table: locations
```sql
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    capacity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Table: stock_movements
```sql
CREATE TABLE stock_movements (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    location_id INTEGER REFERENCES locations(id) ON DELETE CASCADE,
    type VARCHAR(10) CHECK (type IN ('IN', 'OUT')) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## API Endpoints Implementation

### 1. Authentication
**POST /api/auth/login**
- Input: `{"username": "string", "password": "string"}`
- Output: `{"token": "jwt_token", "expires_at": "timestamp"}`
- Hardcode credentials untuk testing: `admin/admin123`

### 2. Products
**GET /api/products** (Protected)
- Query params: `?page=1&limit=10&search=sku`
- Output: List produk dengan pagination

**POST /api/products** (Protected)
- Input: `{"sku_name": "string", "quantity": integer}`
- Validation: sku_name unique, quantity >= 0

**PUT /api/products/:id** (Protected)
- Input: `{"sku_name": "string", "quantity": integer}`
- Update produk existing

### 3. Stock Movements
**POST /api/stock-movements** (Protected)
- Input: `{"product_id": int, "location_id": int, "type": "IN/OUT", "quantity": int}`
- Business Rules:
  - Stock OUT: Cek quantity produk >= quantity movement
  - Stock IN: Cek capacity lokasi tidak melebihi limit
  - Auto-update product.quantity

**GET /api/stock-movements** (Protected)
- Query: `?product_id=1&location_id=2&type=IN&start_date=2024-01-01&end_date=2024-12-31`
- Output: History pergerakan dengan filter

### 4. Locations
**GET /api/locations** (Protected)
- Output: List semua lokasi dengan current capacity usage

---

## Business Rules Implementation

1. **Stock OUT Validation:**
   - Sebelum POST stock movement type=OUT, query product.quantity
   - Jika quantity < requested, return error 400
   - Update: `product.quantity = product.quantity - movement.quantity`

2. **Stock IN Validation:**
   - Query total stock di location: `SUM(quantity) WHERE location_id = X`
   - Jika total + new_quantity > location.capacity, return error 400
   - Update: `product.quantity = product.quantity + movement.quantity`

3. **Auto-Update Product Quantity:**
   - Gunakan database transaction untuk consistency
   - Insert stock_movement dan update products dalam 1 transaction

4. **Authentication Required:**
   - Semua endpoint kecuali /api/auth/login wajib header:
     `Authorization: Bearer <jwt_token>`
   - JWT expire: 24 jam

---

## Technical Requirements

### 1. Project Structure
Gunakan Clean Architecture:
- `cmd/api/main.go` - Entry point
- `internal/config/` - Config & DB connection
- `internal/models/` - Struct definitions
- `internal/repositories/` - Database queries (raw SQL)
- `internal/services/` - Business logic
- `internal/handlers/` - HTTP handlers
- `internal/middleware/` - Auth & logging

### 2. Error Handling
Standard JSON response:
```json
{
  "success": boolean,
  "message": "string",
  "data": object | null,
  "error": "string" | null
}
```

### 3. Environment Variables
```env
DB_HOST=db.pnlcheslucpptcrwcauf.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=leonferdian@supabase
DB_NAME=postgres
JWT_SECRET=your-secret-key-here
PORT=8080
```

### 4. Docker Setup
Buat Dockerfile multi-stage:
- Stage 1: Build binary
- Stage 2: Runtime image (alpine)
- Expose port 8080

### 5. Dependencies
```
github.com/gin-gonic/gin (atau fiber)
github.com/lib/pq (atau pgx)
github.com/golang-jwt/jwt/v5
github.com/joho/godotenv
```

---

## Implementation Steps

1. **Setup Project:**
   - Init Go module
   - Install dependencies
   - Setup folder structure

2. **Database Connection:**
   - Create config.go untuk DB connection
   - Test koneksi ke Supabase
   - Run migration schema

3. **Create Models & Repositories:**
   - Define structs
   - Implement CRUD dengan raw SQL
   - Handle transactions untuk stock movements

4. **Implement Services:**
   - Business logic untuk validation
   - Transaction handling untuk consistency

5. **Build HTTP Handlers:**
   - Request validation
   - Call services
   - Return standard response

6. **Add Middleware:**
   - JWT authentication
   - Request logging
   - Error recovery

7. **Docker Setup:**
   - Create Dockerfile
   - Test build & run

8. **Testing:**
   - Test semua endpoints dengan Postman/curl
   - Verify business rules

---

## Testing Commands

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Create Product
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"sku_name":"PROD-001","quantity":100}'
```

### Stock Movement (IN)
```bash
curl -X POST http://localhost:8080/api/stock-movements \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"location_id":1,"type":"IN","quantity":50}'
```

---

## Deliverables
1. ✅ Working REST API dengan semua endpoints
2. ✅ Database migrations
3. ✅ Dockerfile & docker-compose.yml
4. ✅ README dengan API documentation
5. ✅ .env.example file
6. ✅ Postman collection (optional)

## Success Criteria
- Semua endpoint berfungsi sesuai spesifikasi
- Business rules tervalidasi dengan benar
- Authentication JWT berjalan
- Database transactions maintain consistency
- API response time < 200ms (average)
- Docker image berhasil di-build dan run

---

**Mulai dengan:** 
1. Setup project structure dan go.mod
2. Implement database connection ke Supabase
3. Create dan run migration schema
4. Build authentication system
5. Implement products endpoints
6. Implement stock movements dengan business rules
7. Add Docker support

