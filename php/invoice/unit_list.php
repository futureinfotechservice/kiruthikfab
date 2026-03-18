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

$sql = "SELECT id, companyid, unitname, addedby, activestatus, created_at 
        FROM unitmaster 
        WHERE companyid = '$companyid' AND activestatus = '1' 
        ORDER BY unitname";

$result = $conn->query($sql);
$units = [];

while ($row = $result->fetch_assoc()) {
    $units[] = $row;
}

echo json_encode($units);
$conn->close();
?>