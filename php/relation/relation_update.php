<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$relationid = isset($_POST['relationid']) ? mysqli_real_escape_string($conn, $_POST['relationid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$relation = isset($_POST['relation']) ? mysqli_real_escape_string($conn, $_POST['relation']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['relationid'])) $relationid = mysqli_real_escape_string($conn, $obj['relationid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['relation'])) $relation = mysqli_real_escape_string($conn, $obj['relation']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($relationid)) {
    echo json_encode(["status" => "error", "message" => "Relation ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($relation)) {
    echo json_encode(["status" => "error", "message" => "Relation name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if relation name already exists for another relation
$check_query = "SELECT id FROM relationmaster 
                WHERE companyid = '$companyid' 
                AND relation = '$relation' 
                AND id != '$relationid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Relation name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE relationmaster SET 
        relation = '$relation',
        addedby = '$addedby'
        WHERE id = '$relationid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Relation updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>