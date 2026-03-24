<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$occupationid = isset($_POST['occupationid']) ? mysqli_real_escape_string($conn, $_POST['occupationid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$occupationname = isset($_POST['occupationname']) ? mysqli_real_escape_string($conn, $_POST['occupationname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['occupationid'])) $occupationid = mysqli_real_escape_string($conn, $obj['occupationid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['occupationname'])) $occupationname = mysqli_real_escape_string($conn, $obj['occupationname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($occupationid)) {
    echo json_encode(["status" => "error", "message" => "Occupation ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($occupationname)) {
    echo json_encode(["status" => "error", "message" => "Occupation name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if occupation name already exists for another occupation
$check_query = "SELECT id FROM occupationmaster 
                WHERE companyid = '$companyid' 
                AND occupationname = '$occupationname' 
                AND id != '$occupationid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Occupation name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE occupationmaster SET 
        occupationname = '$occupationname',
        addedby = '$addedby'
        WHERE id = '$occupationid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Occupation updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>