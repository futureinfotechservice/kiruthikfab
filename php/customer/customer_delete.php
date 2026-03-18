<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj)) {
    $customerid = mysqli_real_escape_string($conn, $obj['customerid'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
} else {
    $customerid = mysqli_real_escape_string($conn, $_POST['customerid'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
}

if (empty($customerid) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Customer ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

// Soft delete - update activestatus to 0
// $sql = "UPDATE customermaster SET activestatus = '0' WHERE id = '$customerid' AND companyid = '$companyid'";
$sql = "Delete from customermaster WHERE id = '$customerid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    if (mysqli_affected_rows($conn) > 0) {
        echo json_encode(["status" => "success", "message" => "Customer deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Customer not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>