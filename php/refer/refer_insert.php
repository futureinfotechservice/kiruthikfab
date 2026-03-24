<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$refername = isset($_POST['refername']) ? mysqli_real_escape_string($conn, $_POST['refername']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
$activestatus = isset($_POST['activestatus']) ? mysqli_real_escape_string($conn, $_POST['activestatus']) : '1';

// Validate required fields
if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($refername)) {
    echo json_encode(["status" => "error", "message" => "Refer name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if refer already exists for this company
$check_query = "SELECT id FROM refermaster WHERE companyid = '$companyid' AND refername = '$refername' AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Refer name already exists"]);
    mysqli_close($conn);
    exit();
}

// Insert query
$sql = "INSERT INTO refermaster (companyid, refername, addedby, activestatus) 
        VALUES ('$companyid', '$refername', '$addedby', '$activestatus')";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Refer created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>