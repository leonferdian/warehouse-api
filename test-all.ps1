# Comprehensive API Test Script
$baseUrl = "http://localhost:8080"
$token = ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Warehouse API Complete Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing
    Write-Host "   [OK] Health Check: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Health Check Failed: $_" -ForegroundColor Red
    Write-Host "   Make sure the server is running: go run cmd/api/main.go" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Login
Write-Host "2. Testing Login..." -ForegroundColor Yellow
try {
    $loginBody = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
    $loginData = $response.Content | ConvertFrom-Json
    $token = $loginData.data.token
    Write-Host "   [OK] Login Successful" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 30))..." -ForegroundColor Gray
} catch {
    Write-Host "   [FAIL] Login Failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $token"
}

# Test 3: Create Location
Write-Host "3. Testing Create Location..." -ForegroundColor Yellow
$locationId = $null
try {
    $locationBody = @{
        code = "LOC-001"
        name = "Main Warehouse"
        capacity = 1000
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/locations" -Method POST -Headers $headers -Body $locationBody -ContentType "application/json" -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    $locationId = $data.data.id
    Write-Host "   [OK] Location Created - ID: $locationId" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Create Location Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Get All Locations
Write-Host "4. Testing Get All Locations..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/locations" -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   [OK] Get Locations Successful" -ForegroundColor Green
    Write-Host "   Locations: $($data.data.Count)" -ForegroundColor Gray
    if ($data.data.Count -gt 0 -and -not $locationId) {
        $locationId = $data.data[0].id
    }
} catch {
    Write-Host "   [FAIL] Get Locations Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Create Product
Write-Host "5. Testing Create Product..." -ForegroundColor Yellow
$productId = $null
try {
    $productBody = @{
        sku_name = "PROD-001"
        quantity = 100
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method POST -Headers $headers -Body $productBody -ContentType "application/json" -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    $productId = $data.data.id
    Write-Host "   [OK] Product Created - ID: $productId, SKU: $($data.data.sku_name), Qty: $($data.data.quantity)" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Create Product Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Get All Products
Write-Host "6. Testing Get All Products..." -ForegroundColor Yellow
try {
    $uri = "$baseUrl/api/products?page=1`&limit=10"
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   [OK] Get Products Successful - Total: $($data.data.pagination.total)" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Get Products Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 7: Update Product
Write-Host "7. Testing Update Product..." -ForegroundColor Yellow
if ($productId) {
    try {
        $updateBody = @{
            sku_name = "PROD-001-UPDATED"
            quantity = 150
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$baseUrl/api/products/$productId" -Method PUT -Headers $headers -Body $updateBody -ContentType "application/json" -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        Write-Host "   [OK] Product Updated - SKU: $($data.data.sku_name), Qty: $($data.data.quantity)" -ForegroundColor Green
    } catch {
        Write-Host "   [FAIL] Update Product Failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   [SKIP] No product ID available" -ForegroundColor Yellow
}
Write-Host ""

# Test 8: Create Stock Movement (IN)
Write-Host "8. Testing Stock Movement IN..." -ForegroundColor Yellow
if ($productId -and $locationId) {
    try {
        $movementBody = @{
            product_id = $productId
            location_id = $locationId
            type = "IN"
            quantity = 50
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$baseUrl/api/stock-movements" -Method POST -Headers $headers -Body $movementBody -ContentType "application/json" -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        Write-Host "   [OK] Stock Movement IN Created - ID: $($data.data.id), Qty: $($data.data.quantity)" -ForegroundColor Green
    } catch {
        Write-Host "   [FAIL] Stock Movement IN Failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Error: $responseBody" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   [SKIP] Need product ID and location ID" -ForegroundColor Yellow
}
Write-Host ""

# Test 9: Get Stock Movements
Write-Host "9. Testing Get Stock Movements..." -ForegroundColor Yellow
try {
    $uri = "$baseUrl/api/stock-movements?page=1`&limit=10"
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   [OK] Get Stock Movements - Total: $($data.data.pagination.total)" -ForegroundColor Green
} catch {
    Write-Host "   [FAIL] Get Stock Movements Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 10: Create Stock Movement (OUT)
Write-Host "10. Testing Stock Movement OUT..." -ForegroundColor Yellow
if ($productId -and $locationId) {
    try {
        $movementBody = @{
            product_id = $productId
            location_id = $locationId
            type = "OUT"
            quantity = 20
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$baseUrl/api/stock-movements" -Method POST -Headers $headers -Body $movementBody -ContentType "application/json" -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        Write-Host "   [OK] Stock Movement OUT Created - ID: $($data.data.id), Qty: $($data.data.quantity)" -ForegroundColor Green
    } catch {
        Write-Host "   [FAIL] Stock Movement OUT Failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   [SKIP] Need product ID and location ID" -ForegroundColor Yellow
}
Write-Host ""

# Test 11: Test Business Rules - Insufficient Quantity
Write-Host "11. Testing Business Rule - Insufficient Quantity..." -ForegroundColor Yellow
if ($productId -and $locationId) {
    try {
        $movementBody = @{
            product_id = $productId
            location_id = $locationId
            type = "OUT"
            quantity = 99999
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$baseUrl/api/stock-movements" -Method POST -Headers $headers -Body $movementBody -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
        Write-Host "   [FAIL] Should have rejected insufficient quantity!" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            Write-Host "   [OK] Correctly rejected insufficient quantity (400)" -ForegroundColor Green
        } else {
            Write-Host "   [WARN] Unexpected error: $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   [SKIP] Need product ID and location ID" -ForegroundColor Yellow
}
Write-Host ""

# Test 12: Test Invalid Login
Write-Host "12. Testing Invalid Login..." -ForegroundColor Yellow
try {
    $invalidLoginBody = @{
        username = "wrong"
        password = "wrong"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST -Body $invalidLoginBody -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
    Write-Host "   [FAIL] Should have rejected invalid credentials!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   [OK] Correctly rejected invalid login (401)" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] Unexpected error: $_" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Suite Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan



