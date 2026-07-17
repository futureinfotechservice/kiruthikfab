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
$rawInput = file_get_contents('php://input');
if (empty($rawInput)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Empty request body"
    ]);
    mysqli_close($conn);
    exit();
}

$input = json_decode($rawInput, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid JSON format: " . json_last_error_msg()
    ]);
    mysqli_close($conn);
    exit();
}

// ============================================
// 5. SANITIZE AND VALIDATE INPUTS
// ============================================
$agentid = isset($input['agentid']) ? trim($input['agentid']) : '';
$companyid = isset($input['companyid']) ? trim($input['companyid']) : '';
$agentname = isset($input['agentname']) ? trim($input['agentname']) : '';
$addedby = isset($input['addedby']) ? trim($input['addedby']) : '';

// Validate required fields
if (empty($agentid)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Agent ID is required"
    ]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    mysqli_close($conn);
    exit();
}

if (empty($agentname)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Agent name is required"
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

// Validate agent name length
if (strlen($agentname) < 2 || strlen($agentname) > 100) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Agent name must be between 2 and 100 characters"
    ]);
    mysqli_close($conn);
    exit();
}

// ============================================
// 6. EXECUTE WITH PREPARED STATEMENTS
// ============================================
try {
    // Start transaction for atomic operation
    mysqli_begin_transaction($conn);
    
    // First, verify agent exists and belongs to company
    $verify_sql = "SELECT id FROM agentmaster 
                   WHERE id = ? AND companyid = ? AND activestatus = '1'
                   FOR UPDATE";
    
    $verify_stmt = mysqli_prepare($conn, $verify_sql);
    if (!$verify_stmt) {
        throw new Exception("Prepare verify error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_bind_param($verify_stmt, "ii", $agentid, $companyid);
    
    if (!mysqli_stmt_execute($verify_stmt)) {
        throw new Exception("Execute verify error: " . mysqli_stmt_error($verify_stmt));
    }
    
    $verify_result = mysqli_stmt_get_result($verify_stmt);
    
    if (mysqli_num_rows($verify_result) === 0) {
        mysqli_stmt_close($verify_stmt);
        mysqli_rollback($conn);
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "message" => "Agent not found or already inactive"
        ]);
        mysqli_close($conn);
        exit();
    }
    mysqli_stmt_close($verify_stmt);
    
    // Check if agent name already exists for another agent
    $check_sql = "SELECT id FROM agentmaster 
                  WHERE companyid = ? 
                  AND agentname = ? 
                  AND id != ? 
                  AND activestatus = '1'
                  FOR UPDATE";
    
    $check_stmt = mysqli_prepare($conn, $check_sql);
    if (!$check_stmt) {
        throw new Exception("Prepare check error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_bind_param($check_stmt, "isi", $companyid, $agentname, $agentid);
    
    if (!mysqli_stmt_execute($check_stmt)) {
        throw new Exception("Execute check error: " . mysqli_stmt_error($check_stmt));
    }
    
    $check_result = mysqli_stmt_get_result($check_stmt);
    
    if (mysqli_num_rows($check_result) > 0) {
        mysqli_stmt_close($check_stmt);
        mysqli_rollback($conn);
        http_response_code(409); // Conflict
        echo json_encode([
            "status" => "error",
            "message" => "Agent name already exists for this company"
        ]);
        mysqli_close($conn);
        exit();
    }
    mysqli_stmt_close($check_stmt);
    
    // Update query with prepared statement
    $update_sql = "UPDATE agentmaster SET 
                   agentname = ?,
                   addedby = ?
                   WHERE id = ? AND companyid = ?";
    
    $update_stmt = mysqli_prepare($conn, $update_sql);
    if (!$update_stmt) {
        throw new Exception("Prepare update error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_bind_param($update_stmt, "ssii", $agentname, $addedby, $agentid, $companyid);
    
    if (!mysqli_stmt_execute($update_stmt)) {
        throw new Exception("Execute update error: " . mysqli_stmt_error($update_stmt));
    }
    
    $affectedRows = mysqli_stmt_affected_rows($update_stmt);
    mysqli_stmt_close($update_stmt);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Success response
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "message" => "Agent updated successfully",
        "data" => [
            "id" => $agentid,
            "companyid" => $companyid,
            "agentname" => htmlspecialchars($agentname, ENT_QUOTES, 'UTF-8'),
            "addedby" => htmlspecialchars($addedby, ENT_QUOTES, 'UTF-8')
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback on error
    mysqli_rollback($conn);
    
    // Log the error
    error_log("Update Agent Error: " . $e->getMessage());
    error_log("Agent ID: $agentid, Company ID: $companyid, Name: $agentname");
    
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
?>