<?php
// ============================================
// 1. ERROR REPORTING & LOGGING
// ============================================
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php-error.log');

// ============================================
// 2. CORS HEADERS
// ============================================
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Cache-Control, X-Requested-With");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json; charset=utf-8");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// Allow both GET and POST
if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST'])) {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed. Use GET or POST."
    ]);
    exit();
}

// ============================================
// 3. DATABASE CONNECTION
// ============================================
require_once 'conn.php';

// ============================================
// 4. GET AND VALIDATE INPUT
// ============================================
$companyid = '';

// Support both GET and POST requests
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $companyid = isset($_GET['companyid']) ? trim($_GET['companyid']) : '';
} else {
    // POST request - get from JSON body
    $json = file_get_contents('php://input');
    if (!empty($json)) {
        $obj = json_decode($json, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            $companyid = isset($obj['companyid']) ? trim($obj['companyid']) : '';
        }
    }
}

// Validate required field
if (empty($companyid)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required",
        "data" => []
    ]);
    mysqli_close($conn);
    exit();
}

// Validate companyid is numeric
if (!is_numeric($companyid) || $companyid <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid Company ID format",
        "data" => []
    ]);
    mysqli_close($conn);
    exit();
}

// Convert to integer
$companyid = intval($companyid);

// ============================================
// 5. EXECUTE QUERY WITH PREPARED STATEMENT
// ============================================
try {
    // Use prepared statement to prevent SQL injection
    $sql = "SELECT 
        id, 
        companyid, 
        agentname, 
        addedby, 
        activestatus 
    FROM agentmaster 
    WHERE companyid = ? AND activestatus = '1' 
    ORDER BY agentname ASC";
    
    $stmt = mysqli_prepare($conn, $sql);
    if (!$stmt) {
        throw new Exception("Database prepare error: " . mysqli_error($conn));
    }
    
    // Bind parameter
    mysqli_stmt_bind_param($stmt, "i", $companyid);
    
    // Execute
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Query execution error: " . mysqli_stmt_error($stmt));
    }
    
    // Get result
    $result = mysqli_stmt_get_result($stmt);
    $agents = [];
    
    if ($result && mysqli_num_rows($result) > 0) {
        while ($row = mysqli_fetch_assoc($result)) {
            // Sanitize output
            foreach ($row as $key => $value) {
                $row[$key] = htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
            }
            $agents[] = $row;
        }
    }
    
    // Close statement
    mysqli_stmt_close($stmt);
    
    // ============================================
    // 6. SUCCESS RESPONSE
    // ============================================
    echo json_encode([
        "status" => "success",
        "message" => "Agents fetched successfully",
        "data" => $agents,
        "count" => count($agents)
    ]);
    
} catch (Exception $e) {
    // Log error
    error_log("Fetch Agents Error: " . $e->getMessage());
    error_log("Company ID: $companyid");
    
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database error occurred. Please try again later.",
        "data" => []
    ]);
} finally {
    // Close connection
    if (isset($conn) && !mysqli_connect_errno()) {
        mysqli_close($conn);
    }
}
?>