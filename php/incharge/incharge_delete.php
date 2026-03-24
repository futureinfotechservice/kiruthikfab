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

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['inchargeid'])) $inchargeid = mysqli_real_escape_string($conn, $obj['inchargeid']);
    if (isset($obj['companyid'])) $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
}

if (empty($inchargeid) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Incharge ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

// Soft delete - update activestatus to 0
// $sql = "UPDATE inchargetmaster SET activestatus = '0' WHERE id = '$inchargeid' AND companyid = '$companyid'";
$sql = "Delete From inchargetmaster WHERE id = '$inchargeid' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    if (mysqli_affected_rows($conn) > 0) {
        echo json_encode(["status" => "success", "message" => "Incharge deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Incharge not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>