<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$agentid = isset($_POST['agentid']) ? mysqli_real_escape_string($conn, $_POST['agentid']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$agentname = isset($_POST['agentname']) ? mysqli_real_escape_string($conn, $_POST['agentname']) : '';
$addedby = isset($_POST['addedby']) ? mysqli_real_escape_string($conn, $_POST['addedby']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['agentid'])) $agentid = mysqli_real_escape_string($conn, $obj['agentid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    if (isset($obj['agentname'])) $agentname = mysqli_real_escape_string($conn, $obj['agentname']);
    if (isset($obj['addedby'])) $addedby = mysqli_real_escape_string($conn, $obj['addedby']);
}

// Validate required fields
if (empty($agentid)) {
    echo json_encode(["status" => "error", "message" => "Agent ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

if (empty($agentname)) {
    echo json_encode(["status" => "error", "message" => "Agent name is required"]);
    mysqli_close($conn);
    exit();
}

// Check if agent name already exists for another agent
$check_query = "SELECT id FROM agentmaster 
                WHERE companyid = '$companyid' 
                AND agentname = '$agentname' 
                AND id != '$agentid' 
                AND activestatus = '1'";
$result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Agent name already exists"]);
    mysqli_close($conn);
    exit();
}

// Update query
$sql = "UPDATE agentmaster SET 
        agentname = '$agentname',
        addedby = '$addedby'
        WHERE id = '$agentid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Agent updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>