<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$areaid = isset($_POST['areaid']) ? mysqli_real_escape_string($conn, $_POST['areaid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$areaname = isset($_POST['areaname']) ? mysqli_real_escape_string($conn, $_POST['areaname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['areaid'])) $areaid = mysqli_real_escape_string($conn, $obj['areaid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['areaname'])) $areaname = mysqli_real_escape_string($conn, $obj['areaname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($areaid)) {
    echo json_encode(["status" => "error", "message" => "Area ID is required"]);
    mysqli_close($conn);
    exit();
}

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

// Check if area name already exists for another area
$check_query = "SELECT id FROM areamaster 
                WHERE companyid = '$companyid' 
                AND areaname = '$areaname' 
                AND id != '$areaid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Area name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE areamaster SET 
        areaname = '$areaname',
        addedby = '$addedby'
        WHERE id = '$areaid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Area updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>