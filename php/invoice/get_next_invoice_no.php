<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed"]));
}

$json = file_get_contents('php://input');
$obj = json_decode($json, true);

$companyid = $obj['companyid'];

$sql = "SELECT IFNULL(MAX(CAST(invoiceno AS UNSIGNED)), 0) + 1 as nextno FROM invoice_head WHERE companyid = '$companyid'";
$result = $conn->query($sql);

if ($result && $row = $result->fetch_assoc()) {
    echo json_encode(["success" => true, "nextno" => $row['nextno']]);
} else {
    echo json_encode(["success" => true, "nextno" => 1]);
}

$conn->close();
?>