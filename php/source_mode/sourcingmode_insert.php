<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$sourcingmode_name = isset($_POST['sourcingmode_name']) ? mysqli_real_escape_string($conn, $_POST['sourcingmode_name']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
$activestatus = isset($_POST['activestatus']) ? mysqli_real_escape_string($conn, $_POST['activestatus']) : '1';

// Validate required fields
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

// Check if sourcingmode_name already exists for this company
$check_query = "SELECT id FROM sourcingmode_master WHERE companyid = '$companyid' AND sourcingmode_name = '$sourcingmode_name' AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "sourcingmode_name name already exists"]);
    mysqli_close($conn);
    exit();
}

// Insert query
$sql = "INSERT INTO sourcingmode_master (companyid, sourcingmode_name, addedby, activestatus) 
        VALUES ('$companyid', '$sourcingmode_name', '$addedby', '$activestatus')";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "sourcingmode created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>