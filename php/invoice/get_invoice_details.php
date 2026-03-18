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
$invoiceid = $obj['invoiceid'];

$sql = "SELECT d.id, d.productid, p.productname, d.modelid, m.modelname, 
        d.sizeid, s.sizename, d.unitid, u.unitname, d.quantity, d.rate, d.amount
        FROM invoice_detail d
        LEFT JOIN productmaster p ON d.productid = p.id
        LEFT JOIN modelmaster m ON d.modelid = m.id
        LEFT JOIN sizemaster s ON d.sizeid = s.id
        LEFT JOIN unitmaster u ON d.unitid = u.id
        WHERE d.companyid = '$companyid' AND d.headid = '$invoiceid'
        ORDER BY d.id";

$result = $conn->query($sql);
$details = [];

while ($row = $result->fetch_assoc()) {
    $details[] = $row;
}

echo json_encode($details);
$conn->close();
?>