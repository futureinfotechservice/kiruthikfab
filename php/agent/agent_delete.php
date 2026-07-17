<?php
// ============================================
// 1. ERROR REPORTING & LOGGING
// ============================================
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php-error.log');

// ============================================
// 2. CORS & HEADERS
// ============================================
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Cache-Control, X-Requested-With");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json; charset=utf-8");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// Only allow POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed. Use POST."
    ]);
    exit();
}

// ============================================
// 3. DATABASE CONNECTION
// ============================================
require_once 'conn.php';

// ============================================
// 4. GET AND VALIDATE JSON INPUT
// ============================================
$json = file_get_contents('php://input');
if (empty($json)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Empty request body"
    ]);
    mysqli_close($conn);
    exit();
}

$obj = json_decode($json, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid JSON format"
    ]);
    mysqli_close($conn);
    exit();
}

// Validate required fields
$agentid = isset($obj['agentid']) ? trim($obj['agentid']) : '';
$companyid = isset($obj['companyid']) ? trim($obj['companyid']) : '';

if (empty($agentid) || empty($companyid)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Agent ID and Company ID are required"
    ]);
    mysqli_close($conn);
    exit();
}

// Validate data types
$agentid = filter_var($agentid, FILTER_VALIDATE_INT);
$companyid = filter_var($companyid, FILTER_VALIDATE_INT);

if ($agentid === false || $agentid <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid Agent ID format"
    ]);
    mysqli_close($conn);
    exit();
}

if ($companyid === false || $companyid <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid Company ID format"
    ]);
    mysqli_close($conn);
    exit();
}

// ============================================
// 5. EXECUTE DELETE WITH PREPARED STATEMENT
// ============================================
try {
    // Prepare the delete query
    $sql = "DELETE FROM agentmaster WHERE id = ? AND companyid = ?";
    
    $stmt = mysqli_prepare($conn, $sql);
    if (!$stmt) {
        throw new Exception("Database prepare error: " . mysqli_error($conn));
    }
    
    // Bind parameters
    mysqli_stmt_bind_param($stmt, "ii", $agentid, $companyid);
    
    // Execute the statement
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Delete execution error: " . mysqli_stmt_error($stmt));
    }
    
    // Check if any rows were affected
    $affectedRows = mysqli_stmt_affected_rows($stmt);
    
    if ($affectedRows > 0) {
        echo json_encode([
            "status" => "success",
            "message" => "Agent deleted successfully",
            "deleted_id" => $agentid
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "message" => "Agent not found or already deleted"
        ]);
    }
    
    // Close statement
    mysqli_stmt_close($stmt);
    
} catch (Exception $e) {
    // Log the error
    error_log("Delete Agent Error: " . $e->getMessage());
    error_log("Agent ID: $agentid, Company ID: $companyid");
    
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database error occurred. Please try again later."
    ]);
} finally {
    // Close connection
    if (isset($conn) && !mysqli_connect_errno()) {
        mysqli_close($conn);
    }
}
