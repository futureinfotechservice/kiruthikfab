<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

$source_id = isset($_POST['source_id']) ? mysqli_real_escape_string($conn, $_POST['source_id']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj)) {
    $source_id = mysqli_real_escape_string($conn, $obj['source_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
}

if (empty($source_id) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Source ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

$sql = "UPDATE sourcemaster SET activestatus = '0' WHERE id = '$source_id' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Source deleted successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>