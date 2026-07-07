<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$district_name = isset($_POST['district_name']) ? mysqli_real_escape_string($conn, $_POST['district_name']) : '';
$state = isset($_POST['state']) ? mysqli_real_escape_string($conn, $_POST['state']) : '';
 
// Validate required fields
if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($district_name)) {
    echo json_encode(["status" => "error", "message" => "district_name  is required"]);
    mysqli_close($conn);
    exit();
}

 $check_query = "SELECT id FROM district_master WHERE companyid = '$companyid' AND district_name = '$district_name' AND state = '$state'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "district_name  already exists"]);
    mysqli_close($conn);
    exit();
}

// Insert query
$sql = "INSERT INTO district_master (companyid, district_name, state) 
        VALUES ('$companyid', '$district_name', '$state')";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "district_name created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>