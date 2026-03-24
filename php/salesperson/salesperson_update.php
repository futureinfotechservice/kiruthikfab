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
$salespersonname = isset($_POST['salespersonname']) ? mysqli_real_escape_string($conn, $_POST['salespersonname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['salespersonid'])) $salespersonid = mysqli_real_escape_string($conn, $obj['salespersonid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['salespersonname'])) $salespersonname = mysqli_real_escape_string($conn, $obj['salespersonname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($salespersonid)) {
    echo json_encode(["status" => "error", "message" => "Sales Person ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($salespersonname)) {
    echo json_encode(["status" => "error", "message" => "Sales Person name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if sales person name already exists for another sales person
$check_query = "SELECT id FROM salespersonmaster 
                WHERE companyid = '$companyid' 
                AND salespersonname = '$salespersonname' 
                AND id != '$salespersonid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Sales Person name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE salespersonmaster SET 
        salespersonname = '$salespersonname',
        addedby = '$addedby'
        WHERE id = '$salespersonid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Sales Person updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>