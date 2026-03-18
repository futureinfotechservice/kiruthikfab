<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$unitid = isset($_POST['unitid']) ? mysqli_real_escape_string($conn, $_POST['unitid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$unitname = isset($_POST['unitname']) ? mysqli_real_escape_string($conn, $_POST['unitname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['unitid'])) $unitid = mysqli_real_escape_string($conn, $obj['unitid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['unitname'])) $unitname = mysqli_real_escape_string($conn, $obj['unitname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($unitid)) {
    echo json_encode(["status" => "error", "message" => "Unit ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($unitname)) {
    echo json_encode(["status" => "error", "message" => "Unit name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if unit name already exists for another unit
$check_query = "SELECT id FROM unitmaster 
                WHERE companyid = '$companyid' 
                AND unitname = '$unitname' 
                AND id != '$unitid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Unit name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE unitmaster SET 
        unitname = '$unitname',
        addedby = '$addedby'
        WHERE id = '$unitid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Unit updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>