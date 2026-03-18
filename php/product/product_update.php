<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$productid = isset($_POST['productid']) ? mysqli_real_escape_string($conn, $_POST['productid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$productname = isset($_POST['productname']) ? mysqli_real_escape_string($conn, $_POST['productname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['productid'])) $productid = mysqli_real_escape_string($conn, $obj['productid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['productname'])) $productname = mysqli_real_escape_string($conn, $obj['productname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($productid)) {
    echo json_encode(["status" => "error", "message" => "Product ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($productname)) {
    echo json_encode(["status" => "error", "message" => "Product name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if product name already exists for another product
$check_query = "SELECT id FROM productmaster 
                WHERE companyid = '$companyid' 
                AND productname = '$productname' 
                AND id != '$productid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Product name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE productmaster SET 
        productname = '$productname',
        addedby = '$addedby'
        WHERE id = '$productid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Product updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>