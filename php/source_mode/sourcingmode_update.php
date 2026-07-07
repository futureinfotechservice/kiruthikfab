<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$sourcingmodeid = isset($_POST['sourcingmodeid']) ? mysqli_real_escape_string($conn, $_POST['sourcingmodeid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$sourcingmode_name = isset($_POST['sourcingmode_name']) ? mysqli_real_escape_string($conn, $_POST['sourcingmode_name']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['sourcingmodeid'])) $sourcingmodeid = mysqli_real_escape_string($conn, $obj['sourcingmodeid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['sourcingmode_name'])) $sourcingmode_name = mysqli_real_escape_string($conn, $obj['sourcingmode_name']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($sourcingmodeid)) {
    echo json_encode(["status" => "error", "message" => "sourcingmode ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($sourcingmode_name)) {
    echo json_encode(["status" => "error", "message" => "sourcingmode_name name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if sourcingmode_name name already exists for another sourcingmode_name
$check_query = "SELECT id FROM sourcingmode_master 
                WHERE companyid = '$companyid' 
                AND sourcingmode_name = '$sourcingmode_name' 
                AND id != '$sourcingmodeid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "sourcingmode_name name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE sourcingmode_master SET 
        sourcingmode_name = '$sourcingmode_name',
        addedby = '$addedby'
        WHERE id = '$sourcingmodeid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "sourcingmode_name updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>