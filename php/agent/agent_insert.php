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
$companyid = isset($input['companyid']) ? trim($input['companyid']) : '';
$agentname = isset($input['agentname']) ? trim($input['agentname']) : '';
$addedby = isset($input['addedby']) ? trim($input['addedby']) : '';
$activestatus = isset($input['activestatus']) ? trim($input['activestatus']) : '1';

// Validate required fields
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
$companyid = filter_var($companyid, FILTER_VALIDATE_INT);
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

// Validate active status
if ($activestatus !== '1' && $activestatus !== '0') {
    $activestatus = '1'; // Default to active
}

// ============================================
// 6. EXECUTE WITH PREPARED STATEMENTS
// ============================================
try {
    // Start transaction for atomic operation
    mysqli_begin_transaction($conn);
    
    // Check if agent already exists (with lock for race condition)
    $check_sql = "SELECT id FROM agentmaster 
                  WHERE companyid = ? AND agentname = ? AND activestatus = '1' 
                  FOR UPDATE";
    
    $check_stmt = mysqli_prepare($conn, $check_sql);
    if (!$check_stmt) {
        throw new Exception("Prepare check error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_bind_param($check_stmt, "is", $companyid, $agentname);
    
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
    
    // Insert query with prepared statement
    $insert_sql = "INSERT INTO agentmaster (companyid, agentname, addedby, activestatus) 
                   VALUES (?, ?, ?, ?)";
    
    $insert_stmt = mysqli_prepare($conn, $insert_sql);
    if (!$insert_stmt) {
        throw new Exception("Prepare insert error: " . mysqli_error($conn));
    }
    
    mysqli_stmt_bind_param($insert_stmt, "isss", $companyid, $agentname, $addedby, $activestatus);
    
    if (!mysqli_stmt_execute($insert_stmt)) {
        throw new Exception("Execute insert error: " . mysqli_stmt_error($insert_stmt));
    }
    
    $newId = mysqli_insert_id($conn);
    mysqli_stmt_close($insert_stmt);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Success response
    http_response_code(201); // Created
    echo json_encode([
        "status" => "success",
        "message" => "Agent created successfully",
        "data" => [
            "id" => $newId,
            "companyid" => $companyid,
            "agentname" => htmlspecialchars($agentname, ENT_QUOTES, 'UTF-8'),
            "addedby" => htmlspecialchars($addedby, ENT_QUOTES, 'UTF-8'),
            "activestatus" => $activestatus
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback on error
    mysqli_rollback($conn);
    
    // Log the error
    error_log("Create Agent Error: " . $e->getMessage());
    error_log("Company ID: $companyid, Agent: $agentname");
    
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