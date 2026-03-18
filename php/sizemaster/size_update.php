<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$sizeid = isset($_POST['sizeid']) ? mysqli_real_escape_string($conn, $_POST['sizeid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$sizename = isset($_POST['sizename']) ? mysqli_real_escape_string($conn, $_POST['sizename']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['sizeid'])) $sizeid = mysqli_real_escape_string($conn, $obj['sizeid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['sizename'])) $sizename = mysqli_real_escape_string($conn, $obj['sizename']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($sizeid)) {
    echo json_encode(["status" => "error", "message" => "Size ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($sizename)) {
    echo json_encode(["status" => "error", "message" => "Size name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if size name already exists for another size
$check_query = "SELECT id FROM sizemaster 
                WHERE companyid = '$companyid' 
                AND sizename = '$sizename' 
                AND id != '$sizeid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Size name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE sizemaster SET 
        sizename = '$sizename',
        addedby = '$addedby'
        WHERE id = '$sizeid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Size updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>