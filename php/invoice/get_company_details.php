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

$sql = "SELECT `id`, `companyname`, `gstno`, `contactno`, `address`, `email_id`, `logourl`, `activestatus`,`website`,`show_email_id` 
        FROM `companymaster` 
        WHERE `id` = '$companyid' AND `activestatus` = 'Active'";

$result = $conn->query($sql);
$company = [];

while ($row = $result->fetch_assoc()) {
    $company[] = $row;
}

echo json_encode($company);
$conn->close();
?>