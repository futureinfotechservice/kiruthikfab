<?php
include 'conn.php';
include 'cors.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$delivery_person_id = isset($_POST['delivery_person_id']) ? mysqli_real_escape_string($conn, $_POST['delivery_person_id']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$name = isset($_POST['name']) ? mysqli_real_escape_string($conn, $_POST['name']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['delivery_person_id']))
        $delivery_person_id = mysqli_real_escape_string($conn, $obj['delivery_person_id']);
    if (isset($obj['companyid']))
        $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['name']))
        $name = mysqli_real_escape_string($conn, $obj['name']);
    if (isset($obj['addedby']))
        $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($delivery_person_id)) {
    echo json_encode(["status" => "error", "message" => "Delivery Person ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($name)) {
    echo json_encode(["status" => "error", "message" => "Delivery Person name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if name name already exists for another name
$check_query = "SELECT id FROM delivery_person_master 
                WHERE companyid = '$companyid' 
                AND name = '$name' 
                AND id != '$delivery_person_id' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Delivery Person name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE delivery_person_master SET 
        name = '$name',
        addedby = '$addedby'
        WHERE id = '$delivery_person_id' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Delivery Person updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>