<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$inchargeid = isset($_POST['inchargeid']) ? mysqli_real_escape_string($conn, $_POST['inchargeid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$inchargetname = isset($_POST['inchargetname']) ? mysqli_real_escape_string($conn, $_POST['inchargetname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['inchargeid'])) $inchargeid = mysqli_real_escape_string($conn, $obj['inchargeid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['inchargetname'])) $inchargetname = mysqli_real_escape_string($conn, $obj['inchargetname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($inchargeid)) {
    echo json_encode(["status" => "error", "message" => "Incharge ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($inchargetname)) {
    echo json_encode(["status" => "error", "message" => "Incharge name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if incharge name already exists for another incharge
$check_query = "SELECT id FROM inchargetmaster 
                WHERE companyid = '$companyid' 
                AND inchargetname = '$inchargetname' 
                AND id != '$inchargeid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Incharge name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE inchargetmaster SET 
        inchargetname = '$inchargetname',
        addedby = '$addedby'
        WHERE id = '$inchargeid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Incharge updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>