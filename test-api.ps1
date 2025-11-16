# Warehouse API Test Script
$baseUrl = "http://localhost:8080"
$token = ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Warehouse API Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing
    Write-Host "   ✓ Health Check: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Health Check Failed: $_" -ForegroundColor Red
    Write-Host "   Make sure the server is running!" -ForegroundColor Red
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
    Write-Host "   ✓ Login Successful" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host "   Expires At: $($loginData.data.expires_at)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Login Failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Error: $responseBody" -ForegroundColor Red
    }
    exit 1
}
Write-Host ""

# Test 3: Get All Products (Empty)
Write-Host "3. Testing Get All Products (Empty)..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    $response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Get Products Successful" -ForegroundColor Green
    Write-Host "   Total: $($data.data.pagination.total)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Get Products Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Create Product
Write-Host "4. Testing Create Product..." -ForegroundColor Yellow
$productId = $null
try {
    $productBody = @{
        sku_name = "PROD-001"
        quantity = 100
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method POST -Headers $headers -Body $productBody -ContentType "application/json" -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    $productId = $data.data.id
    Write-Host "   ✓ Create Product Successful" -ForegroundColor Green
    Write-Host "   Product ID: $productId" -ForegroundColor Gray
    Write-Host "   SKU: $($data.data.sku_name)" -ForegroundColor Gray
    Write-Host "   Quantity: $($data.data.quantity)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Create Product Failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Error: $responseBody" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: Create Another Product
Write-Host "5. Testing Create Another Product..." -ForegroundColor Yellow
$productId2 = $null
try {
    $productBody = @{
        sku_name = "PROD-002"
        quantity = 50
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method POST -Headers $headers -Body $productBody -ContentType "application/json" -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    $productId2 = $data.data.id
    Write-Host "   ✓ Create Product 2 Successful" -ForegroundColor Green
    Write-Host "   Product ID: $productId2" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Create Product 2 Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Get All Products (With Data)
Write-Host "6. Testing Get All Products (With Data)..." -ForegroundColor Yellow
try {
    $uri = "$baseUrl/api/products?page=1`&limit=10"
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Get Products Successful" -ForegroundColor Green
    Write-Host "   Total Products: $($data.data.pagination.total)" -ForegroundColor Gray
    Write-Host "   Products:" -ForegroundColor Gray
    foreach ($product in $data.data.products) {
        Write-Host "     - ID: $($product.id), SKU: $($product.sku_name), Qty: $($product.quantity)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Get Products Failed: $_" -ForegroundColor Red
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
        Write-Host "   ✓ Update Product Successful" -ForegroundColor Green
        Write-Host "   Updated SKU: $($data.data.sku_name)" -ForegroundColor Gray
        Write-Host "   Updated Quantity: $($data.data.quantity)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ Update Product Failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠ Skipped (No product ID)" -ForegroundColor Yellow
}
Write-Host ""

# Test 8: Get All Locations
Write-Host "8. Testing Get All Locations..." -ForegroundColor Yellow
$locationId = $null
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/locations" -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Get Locations Successful" -ForegroundColor Green
    if ($data.data.Count -gt 0) {
        $locationId = $data.data[0].id
        Write-Host "   Locations Found: $($data.data.Count)" -ForegroundColor Gray
        foreach ($location in $data.data) {
            Write-Host "     - ID: $($location.id), Code: $($location.code), Name: $($location.name), Capacity: $($location.capacity), Usage: $($location.current_usage)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ⚠ No locations found. You may need to create locations manually in the database." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ✗ Get Locations Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 9: Create Stock Movement (IN)
Write-Host "9. Testing Create Stock Movement (IN)..." -ForegroundColor Yellow
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
        Write-Host "   ✓ Stock Movement IN Successful" -ForegroundColor Green
        Write-Host "   Movement ID: $($data.data.id)" -ForegroundColor Gray
        Write-Host "   Type: $($data.data.type)" -ForegroundColor Gray
        Write-Host "   Quantity: $($data.data.quantity)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ Stock Movement IN Failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Error: $responseBody" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ⚠ Skipped (Need product ID and location ID)" -ForegroundColor Yellow
}
Write-Host ""

# Test 10: Get Stock Movements
Write-Host "10. Testing Get Stock Movements..." -ForegroundColor Yellow
try {
    $uri = "$baseUrl/api/stock-movements?page=1`&limit=10"
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Get Stock Movements Successful" -ForegroundColor Green
    Write-Host "   Total Movements: $($data.data.pagination.total)" -ForegroundColor Gray
    if ($data.data.movements.Count -gt 0) {
        Write-Host "   Movements:" -ForegroundColor Gray
        foreach ($movement in $data.data.movements) {
            Write-Host "     - ID: $($movement.id), Type: $($movement.type), Qty: $($movement.quantity), Product: $($movement.product_id), Location: $($movement.location_id)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ✗ Get Stock Movements Failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 11: Create Stock Movement (OUT)
Write-Host "11. Testing Create Stock Movement (OUT)..." -ForegroundColor Yellow
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
        Write-Host "   ✓ Stock Movement OUT Successful" -ForegroundColor Green
        Write-Host "   Movement ID: $($data.data.id)" -ForegroundColor Gray
        Write-Host "   Type: $($data.data.type)" -ForegroundColor Gray
        Write-Host "   Quantity: $($data.data.quantity)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ Stock Movement OUT Failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Error: $responseBody" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ⚠ Skipped (Need product ID and location ID)" -ForegroundColor Yellow
}
Write-Host ""

# Test 12: Test Error Cases
Write-Host "12. Testing Error Cases..." -ForegroundColor Yellow

# Test Invalid Login
Write-Host "   12a. Testing Invalid Login..." -ForegroundColor Yellow
try {
    $invalidLoginBody = @{
        username = "wrong"
        password = "wrong"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST -Body $invalidLoginBody -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
    Write-Host "      ✗ Should have failed!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "      ✓ Invalid Login Correctly Rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ Unexpected error: $_" -ForegroundColor Yellow
    }
}

# Test Unauthorized Access
Write-Host "   12b. Testing Unauthorized Access..." -ForegroundColor Yellow
try {
    $badHeaders = @{
        "Authorization" = "Bearer invalid-token"
    }
    $response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method GET -Headers $badHeaders -UseBasicParsing -ErrorAction Stop
    Write-Host "      ✗ Should have failed!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "      ✓ Unauthorized Access Correctly Rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ Unexpected error: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Suite Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

