<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$referid = isset($_POST['referid']) ? mysqli_real_escape_string($conn, $_POST['referid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$refername = isset($_POST['refername']) ? mysqli_real_escape_string($conn, $_POST['refername']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['referid'])) $referid = mysqli_real_escape_string($conn, $obj['referid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['refername'])) $refername = mysqli_real_escape_string($conn, $obj['refername']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($referid)) {
    echo json_encode(["status" => "error", "message" => "Refer ID is required"]);
    mysqli_close($conn);
    exit();
}

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

// Check if refer name already exists for another refer
$check_query = "SELECT id FROM refermaster 
                WHERE companyid = '$companyid' 
                AND refername = '$refername' 
                AND id != '$referid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Refer name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE refermaster SET 
        refername = '$refername',
        addedby = '$addedby'
        WHERE id = '$referid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Refer updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>