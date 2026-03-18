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

$sql = "SELECT id, companyid, customername, gst_no, address, area, areaid, 
        mobile1, mobile2, whatsapp, refer, incharge, agent, salesperson, 
        occupation, aadharurl, photourl, addedby, activestatus, created_at 
        FROM customermaster 
        WHERE companyid = '$companyid' AND activestatus = '1' 
        ORDER BY customername";

$result = $conn->query($sql);
$customers = [];

while ($row = $result->fetch_assoc()) {
    $customers[] = $row;
}

echo json_encode($customers);
$conn->close();
?>