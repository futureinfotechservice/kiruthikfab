<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$areaname = isset($_POST['areaname']) ? mysqli_real_escape_string($conn, $_POST['areaname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';
$activestatus = isset($_POST['activestatus']) ? mysqli_real_escape_string($conn, $_POST['activestatus']) : '1';

// Validate required fields
if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($areaname)) {
    echo json_encode(["status" => "error", "message" => "Area name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if area already exists for this company
$check_query = "SELECT id FROM areamaster WHERE companyid = '$companyid' AND areaname = '$areaname' AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Area name already exists"]);
    mysqli_close($conn);
    exit();
}

// Insert query
$sql = "INSERT INTO areamaster (companyid, areaname, addedby, activestatus) 
        VALUES ('$companyid', '$areaname', '$addedby', '$activestatus')";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Area created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>