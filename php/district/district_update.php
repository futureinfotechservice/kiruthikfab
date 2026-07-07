<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$districtid = isset($_POST['districtid']) ? mysqli_real_escape_string($conn, $_POST['districtid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$district_name = isset($_POST['district_name']) ? mysqli_real_escape_string($conn, $_POST['district_name']) : '';
$state = isset($_POST['state']) ? mysqli_real_escape_string($conn, $_POST['state']) : '';
 
// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['districtid'])) $districtid = mysqli_real_escape_string($conn, $obj['districtid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['district_name'])) $district_name = mysqli_real_escape_string($conn, $obj['district_name']);
    if (isset($obj['state'])) $state = mysqli_real_escape_string($conn, $obj['state']);
}

// Validate required fields
if (empty($districtid)) {
    echo json_encode(["status" => "error", "message" => "District ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($district_name)) {
    echo json_encode(["status" => "error", "message" => "District name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if district name already exists for another district
$check_query = "SELECT id FROM district_master 
                WHERE companyid = '$companyid' 
                AND district_name = '$district_name' 
                AND id != '$districtid' 
                AND state = '$state'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "District name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE district_master SET 
        district_name = '$district_name',
        state = '$state'
        WHERE id = '$districtid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "District updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>