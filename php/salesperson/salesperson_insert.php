<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$salespersonname = isset($_POST['salespersonname']) ? mysqli_real_escape_string($conn, $_POST['salespersonname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
$activestatus = isset($_POST['activestatus']) ? mysqli_real_escape_string($conn, $_POST['activestatus']) : '1';

// Validate required fields
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

// Check if sales person already exists for this company
$check_query = "SELECT id FROM salespersonmaster WHERE companyid = '$companyid' AND salespersonname = '$salespersonname' AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Sales Person name already exists"]);
    mysqli_close($conn);
    exit();
}

// Insert query
$sql = "INSERT INTO salespersonmaster (companyid, salespersonname, addedby, activestatus) 
        VALUES ('$companyid', '$salespersonname', '$addedby', '$activestatus')";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Sales Person created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>