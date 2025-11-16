# Complete Comprehensive API Test Suite
$baseUrl = "http://localhost:8080"
$token = ""
$testResults = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$ExpectedStatus = 200,
        [string]$Description = ""
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    if ($Description) {
        Write-Host "  $Description" -ForegroundColor Gray
    }
    
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $Headers
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params -ErrorAction Stop
        $statusCode = [int]$response.StatusCode
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "  [PASS] Status: $statusCode" -ForegroundColor Green
            $script:testResults += @{Test=$Name; Status="PASS"; Expected=$ExpectedStatus; Actual=$statusCode}
            return $true
        } else {
            Write-Host "  [FAIL] Expected $ExpectedStatus, got $statusCode" -ForegroundColor Red
            $script:testResults += @{Test=$Name; Status="FAIL"; Expected=$ExpectedStatus; Actual=$statusCode}
            return $false
        }
    } catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "  [PASS] Status: $statusCode (Expected error)" -ForegroundColor Green
            $script:testResults += @{Test=$Name; Status="PASS"; Expected=$ExpectedStatus; Actual=$statusCode}
            return $true
        } else {
            Write-Host "  [FAIL] Expected $ExpectedStatus, got $statusCode" -ForegroundColor Red
            if ($_.Exception.Response) {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "  Error: $responseBody" -ForegroundColor Red
            }
            $script:testResults += @{Test=$Name; Status="FAIL"; Expected=$ExpectedStatus; Actual=$statusCode}
            return $false
        }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPREHENSIVE API TEST SUITE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Health Check
Test-Endpoint -Name "Health Check" -Method "GET" -Uri "$baseUrl/health"

# 2. Login
$loginBody = @{username="admin"; password="admin123"} | ConvertTo-Json
$loginPassed = Test-Endpoint -Name "Login" -Method "POST" -Uri "$baseUrl/api/auth/login" -Body $loginBody

if ($loginPassed) {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
        $loginData = $response.Content | ConvertFrom-Json
        $token = $loginData.data.token
        $headers = @{"Authorization" = "Bearer $token"}
        Write-Host "  Token obtained successfully" -ForegroundColor Gray
    } catch {
        Write-Host "  [WARN] Could not obtain token for subsequent tests" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Login failed, skipping authenticated tests" -ForegroundColor Yellow
    $headers = @{"Authorization" = "Bearer invalid"}
}

# 3. Invalid Login
$invalidLogin = @{username="wrong"; password="wrong"} | ConvertTo-Json
Test-Endpoint -Name "Invalid Login" -Method "POST" -Uri "$baseUrl/api/auth/login" -Body $invalidLogin -ExpectedStatus 401 -Description "Should reject invalid credentials"

# 4. Unauthorized Access
Test-Endpoint -Name "Unauthorized Access" -Method "GET" -Uri "$baseUrl/api/products" -Headers @{"Authorization"="Bearer invalid"} -ExpectedStatus 401 -Description "Should reject invalid token"

# 5. Create Location
$locationBody = @{code="LOC-001"; name="Main Warehouse"; capacity=1000} | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$baseUrl/api/locations" -Method POST -Headers $headers -Body $locationBody -ContentType "application/json" -UseBasicParsing
$locationData = $response.Content | ConvertFrom-Json
$locationId = $locationData.data.id

Test-Endpoint -Name "Create Location" -Method "POST" -Uri "$baseUrl/api/locations" -Headers $headers -Body $locationBody

# 6. Duplicate Location Code
Test-Endpoint -Name "Duplicate Location Code" -Method "POST" -Uri "$baseUrl/api/locations" -Headers $headers -Body $locationBody -ExpectedStatus 400 -Description "Should reject duplicate location code"

# 7. Get All Locations
Test-Endpoint -Name "Get All Locations" -Method "GET" -Uri "$baseUrl/api/locations" -Headers $headers

# 8. Create Product
$productBody = @{sku_name="PROD-001"; quantity=100} | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method POST -Headers $headers -Body $productBody -ContentType "application/json" -UseBasicParsing
$productData = $response.Content | ConvertFrom-Json
$productId = $productData.data.id

Test-Endpoint -Name "Create Product" -Method "POST" -Uri "$baseUrl/api/products" -Headers $headers -Body $productBody

# 9. Duplicate SKU
Test-Endpoint -Name "Duplicate SKU" -Method "POST" -Uri "$baseUrl/api/products" -Headers $headers -Body $productBody -ExpectedStatus 400 -Description "Should reject duplicate SKU name"

# 10. Create Product with Zero Quantity (should be allowed)
$productBodyZero = @{sku_name="PROD-002"; quantity=0} | ConvertTo-Json
Test-Endpoint -Name "Product with Zero Quantity" -Method "POST" -Uri "$baseUrl/api/products" -Headers $headers -Body $productBodyZero -Description "Zero quantity should be allowed"

# 11. Get All Products
Test-Endpoint -Name "Get All Products" -Method "GET" -Uri "$baseUrl/api/products" -Headers $headers

# 12. Get Products with Pagination
Test-Endpoint -Name "Get Products with Pagination" -Method "GET" -Uri "$baseUrl/api/products?page=1`&limit=5" -Headers $headers -Description "Test pagination"

# 13. Get Products with Search
Test-Endpoint -Name "Get Products with Search" -Method "GET" -Uri "$baseUrl/api/products?search=PROD" -Headers $headers -Description "Test search functionality"

# 14. Update Product
$updateBody = @{sku_name="PROD-001-UPDATED"; quantity=150} | ConvertTo-Json
Test-Endpoint -Name "Update Product" -Method "PUT" -Uri "$baseUrl/api/products/$productId" -Headers $headers -Body $updateBody

# 15. Update Product with Invalid ID
Test-Endpoint -Name "Update Non-existent Product" -Method "PUT" -Uri "$baseUrl/api/products/99999" -Headers $headers -Body $updateBody -ExpectedStatus 404 -Description "Should return 404 for non-existent product"

# 16. Create Stock Movement IN
$movementInBody = @{product_id=$productId; location_id=$locationId; type="IN"; quantity=50} | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$baseUrl/api/stock-movements" -Method POST -Headers $headers -Body $movementInBody -ContentType "application/json" -UseBasicParsing
$movementData = $response.Content | ConvertFrom-Json

Test-Endpoint -Name "Stock Movement IN" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $movementInBody

# 17. Stock Movement with Invalid Product ID
$invalidProductBody = @{product_id=99999; location_id=$locationId; type="IN"; quantity=10} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement Invalid Product" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $invalidProductBody -ExpectedStatus 404 -Description "Should reject non-existent product"

# 18. Stock Movement with Invalid Location ID
$invalidLocationBody = @{product_id=$productId; location_id=99999; type="IN"; quantity=10} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement Invalid Location" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $invalidLocationBody -ExpectedStatus 404 -Description "Should reject non-existent location"

# 19. Stock Movement with Invalid Type
$invalidTypeBody = @{product_id=$productId; location_id=$locationId; type="INVALID"; quantity=10} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement Invalid Type" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $invalidTypeBody -ExpectedStatus 400 -Description "Should reject invalid type (not IN/OUT)"

# 20. Stock Movement OUT
$movementOutBody = @{product_id=$productId; location_id=$locationId; type="OUT"; quantity=20} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement OUT" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $movementOutBody

# 21. Stock Movement OUT - Insufficient Quantity
$insufficientBody = @{product_id=$productId; location_id=$locationId; type="OUT"; quantity=99999} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement OUT Insufficient" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $insufficientBody -ExpectedStatus 400 -Description "Should reject insufficient product quantity"

# 22. Stock Movement IN - Capacity Exceeded
# First, fill up the location
$fillLocationBody = @{product_id=$productId; location_id=$locationId; type="IN"; quantity=950} | ConvertTo-Json
Invoke-WebRequest -Uri "$baseUrl/api/stock-movements" -Method POST -Headers $headers -Body $fillLocationBody -ContentType "application/json" -UseBasicParsing | Out-Null

$exceedCapacityBody = @{product_id=$productId; location_id=$locationId; type="IN"; quantity=100} | ConvertTo-Json
Test-Endpoint -Name "Stock Movement IN Capacity Exceeded" -Method "POST" -Uri "$baseUrl/api/stock-movements" -Headers $headers -Body $exceedCapacityBody -ExpectedStatus 400 -Description "Should reject when location capacity exceeded"

# 23. Get Stock Movements
Test-Endpoint -Name "Get Stock Movements" -Method "GET" -Uri "$baseUrl/api/stock-movements" -Headers $headers

# 24. Get Stock Movements with Product Filter
Test-Endpoint -Name "Get Stock Movements by Product" -Method "GET" -Uri "$baseUrl/api/stock-movements?product_id=$productId" -Headers $headers -Description "Test product_id filter"

# 25. Get Stock Movements with Location Filter
Test-Endpoint -Name "Get Stock Movements by Location" -Method "GET" -Uri "$baseUrl/api/stock-movements?location_id=$locationId" -Headers $headers -Description "Test location_id filter"

# 26. Get Stock Movements with Type Filter
Test-Endpoint -Name "Get Stock Movements by Type" -Method "GET" -Uri "$baseUrl/api/stock-movements?type=IN" -Headers $headers -Description "Test type filter"

# 27. Get Stock Movements with Date Range
$today = Get-Date -Format "yyyy-MM-dd"
Test-Endpoint -Name "Get Stock Movements by Date Range" -Method "GET" -Uri "$baseUrl/api/stock-movements?start_date=2024-01-01`&end_date=$today" -Headers $headers -Description "Test date range filter"

# 28. Get Stock Movements with Pagination
Test-Endpoint -Name "Get Stock Movements Pagination" -Method "GET" -Uri "$baseUrl/api/stock-movements?page=1`&limit=5" -Headers $headers -Description "Test pagination"

# 29. Update Product to Duplicate SKU
$product2Body = @{sku_name="PROD-003"; quantity=50} | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$baseUrl/api/products" -Method POST -Headers $headers -Body $product2Body -ContentType "application/json" -UseBasicParsing
$product2Data = $response.Content | ConvertFrom-Json
$product2Id = $product2Data.data.id

$duplicateSkuUpdate = @{sku_name="PROD-001-UPDATED"; quantity=100} | ConvertTo-Json
Test-Endpoint -Name "Update Product Duplicate SKU" -Method "PUT" -Uri "$baseUrl/api/products/$product2Id" -Headers $headers -Body $duplicateSkuUpdate -ExpectedStatus 400 -Description "Should reject update to duplicate SKU"

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passed = ($testResults | Where-Object {$_.Status -eq "PASS"}).Count
$failed = ($testResults | Where-Object {$_.Status -eq "FAIL"}).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) {"Red"} else {"Green"})
Write-Host ""

if ($failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    $testResults | Where-Object {$_.Status -eq "FAIL"} | ForEach-Object {
        Write-Host "  - $($_.Test): Expected $($_.Expected), got $($_.Actual)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test Coverage:" -ForegroundColor Cyan
Write-Host "  [OK] Authentication (Login, Invalid Login, Unauthorized)" -ForegroundColor Green
Write-Host "  [OK] Location Management (Create, Duplicate, List)" -ForegroundColor Green
Write-Host "  [OK] Product Management (Create, Duplicate, Update, Search, Pagination)" -ForegroundColor Green
Write-Host "  [OK] Stock Movements (IN, OUT, Filters, Business Rules)" -ForegroundColor Green
Write-Host "  [OK] Error Handling (404, 400, 401)" -ForegroundColor Green
Write-Host ""


