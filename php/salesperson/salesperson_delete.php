<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$salespersonid = isset($_POST['salespersonid']) ? mysqli_real_escape_string($conn, $_POST['salespersonid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['salespersonid'])) $salespersonid = mysqli_real_escape_string($conn, $obj['salespersonid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
}

if (empty($salespersonid) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Sales Person ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

// Soft delete - update activestatus to 0
// $sql = "UPDATE salespersonmaster SET activestatus = '0' WHERE id = '$salespersonid' AND companyid = '$companyid'";
$sql = "Delete from salespersonmaster WHERE id = '$salespersonid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    if (mysqli_affected_rows($conn) > 0) {
        echo json_encode(["status" => "success", "message" => "Sales Person deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Sales Person not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>