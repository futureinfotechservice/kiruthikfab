<?php
include 'conn.php';
include 'cors.php';

// Set content type header
header('Content-Type: application/json');

// Get JSON input
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

// Check if JSON is valid
if ($obj === null) {
    echo json_encode(["status" => "error", "message" => "Invalid JSON data"]);
    mysqli_close($conn);
    exit();
}

// Get values with validation
$companyid = isset($obj['companyid']) ? mysqli_real_escape_string($conn, $obj['companyid']) : '';
$userType = isset($obj['user_type']) ? mysqli_real_escape_string($conn, $obj['user_type']) : '';
$userId = isset($obj['user_id']) ? mysqli_real_escape_string($conn, $obj['user_id']) : '';

// Validate companyid
if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

// Check user type
if (strtoupper($userType) == "ADMIN") {

    $sql = "SELECT
        (SELECT COUNT(*) FROM sourcemaster WHERE companyid = ?) AS source,
        (SELECT COUNT(DISTINCT source_id) FROM call_register WHERE companyid = ?) AS called,
        (SELECT COUNT(*) FROM kyc_master WHERE companyid = ?) AS kyc,
        (SELECT SUM(grandtotal) FROM invoice_head WHERE companyid = ?) AS value";

    $stmt = mysqli_prepare($conn, $sql);
    mysqli_stmt_bind_param($stmt, "iiii", $companyid, $companyid, $companyid, $companyid);
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    $row = mysqli_fetch_assoc($result);

    // Handle null values
    $source = $row['source'] ?? 0;
    $called = $row['called'] ?? 0;
    $kyc = $row['kyc'] ?? 0;
    $value = $row['value'] ?? 0;

    echo json_encode([
        "status" => "success",
        "data" => [
            "source" => intval($source),
            "called" => intval($called),
            "notCalled" => intval($source) - intval($called),
            "kyc" => intval($kyc),
            "value" => floatval($value),
        ]
    ]);
} else {

    $sql = "SELECT
        (SELECT COUNT(*) FROM sourcemaster WHERE companyid = ? and sales_person_id= ?) AS source,
        (SELECT COUNT(DISTINCT source_id) FROM call_register WHERE companyid = ? and call_by_id= ?) AS called,
        (SELECT COUNT(*) FROM kyc_master WHERE companyid = ? and addedby= ?) AS kyc,
        (SELECT SUM(grandtotal) FROM invoice_head WHERE companyid = ? and addedby=?) AS value";

    $stmt = mysqli_prepare($conn, $sql);
    mysqli_stmt_bind_param($stmt, "iiiiiiii", $companyid, $userId, $companyid, $userId, $companyid, $userId, $companyid, $userId);
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    $row = mysqli_fetch_assoc($result);

    // Handle null values
    $source = $row['source'] ?? 0;
    $called = $row['called'] ?? 0;
    $kyc = $row['kyc'] ?? 0;
    $value = $row['value'] ?? 0;

    echo json_encode([
        "status" => "success",
        "data" => [
            "source" => intval($source),
            "called" => intval($called),
            "notCalled" => intval($source) - intval($called),
            "kyc" => intval($kyc),
            "value" => floatval($value),
        ]
    ]);
}
mysqli_close($conn);
exit();
