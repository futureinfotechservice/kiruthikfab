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

$sql = "SELECT id, companyid, modelname, addedby, activestatus, created_at 
        FROM modelmaster 
        WHERE companyid = '$companyid' AND activestatus = '1' 
        ORDER BY modelname";

$result = $conn->query($sql);
$models = [];

while ($row = $result->fetch_assoc()) {
    $models[] = $row;
}

echo json_encode($models);
$conn->close();
?>