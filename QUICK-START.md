# Quick Start Guide

## Server Status
✅ **Server is RUNNING on http://localhost:8080**

## Quick Test Commands

### 1. Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/health" -Method GET
```

### 2. Login
```powershell
$body = @{username="admin"; password="admin123"} | ConvertTo-Json
$response = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $body -ContentType "application/json"
$token = ($response.Content | ConvertFrom-Json).data.token
```

### 3. Create Location
```powershell
$headers = @{"Authorization" = "Bearer $token"}
$body = @{code="LOC-001"; name="Main Warehouse"; capacity=1000} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/locations" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```

### 4. Create Product
```powershell
$body = @{sku_name="PROD-001"; quantity=100} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/products" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```

### 5. Create Stock Movement
```powershell
$body = @{product_id=1; location_id=1; type="IN"; quantity=50} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/stock-movements" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```

## API Endpoints

### Public
- `GET /health` - Health check
- `POST /api/auth/login` - Login

### Protected (Require Bearer Token)
- `GET /api/products` - List products
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `GET /api/locations` - List locations
- `POST /api/locations` - Create location
- `POST /api/stock-movements` - Create stock movement
- `GET /api/stock-movements` - List stock movements

## Using cURL (Alternative)

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Create Product (with token)
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"sku_name":"PROD-001","quantity":100}'
```

## Stop Server
Press `Ctrl+C` in the terminal where the server is running, or close the PowerShell window.

## View Logs
The server logs all requests automatically. Check the terminal where `go run cmd/api/main.go` is running.

