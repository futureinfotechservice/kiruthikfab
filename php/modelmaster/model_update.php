<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$modelid = isset($_POST['modelid']) ? mysqli_real_escape_string($conn, $_POST['modelid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$modelname = isset($_POST['modelname']) ? mysqli_real_escape_string($conn, $_POST['modelname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['modelid'])) $modelid = mysqli_real_escape_string($conn, $obj['modelid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['modelname'])) $modelname = mysqli_real_escape_string($conn, $obj['modelname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($modelid)) {
    echo json_encode(["status" => "error", "message" => "Model ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($modelname)) {
    echo json_encode(["status" => "error", "message" => "Model name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if model name already exists for another model
$check_query = "SELECT id FROM modelmaster 
                WHERE companyid = '$companyid' 
                AND modelname = '$modelname' 
                AND id != '$modelid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Model name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE modelmaster SET 
        modelname = '$modelname',
        addedby = '$addedby'
        WHERE id = '$modelid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Model updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>