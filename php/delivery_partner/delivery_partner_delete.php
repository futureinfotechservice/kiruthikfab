<?php
include 'conn.php';
include 'cors.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$delivery_partner_id = isset($_POST['delivery_partner_id']) ? mysqli_real_escape_string($conn, $_POST['delivery_partner_id']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['delivery_partner_id']))
        $delivery_partner_id = mysqli_real_escape_string($conn, $obj['delivery_partner_id']);
    if (isset($obj['companyid']))
        $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
}

if (empty($delivery_partner_id) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Delivery Partner  ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

// Soft delete - update activestatus to 0
// $sql = "UPDATE delivery_partner_master SET activestatus = '0' WHERE id = '$delivery_partner_id' AND companyid = '$companyid'";
$sql = "Delete from delivery_person_master WHERE id = '$delivery_partner_id' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    if (mysqli_affected_rows($conn) > 0) {
        echo json_encode(["status" => "success", "message" => "Delivery Partner  deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Delivery Partner  not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>