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

$sql = "SELECT h.id, h.invoiceno, h.customerid, c.customername, h.date, 
        h.remarks, h.taxpercentage, h.subtotal, h.grandtotal, h.status, h.addedby, h.created_at
        FROM invoice_head h
        LEFT JOIN customermaster c ON h.customerid = c.id
        WHERE h.companyid = '$companyid'
        ORDER BY h.id DESC";

$result = $conn->query($sql);
$invoices = [];

while ($row = $result->fetch_assoc()) {
    $invoices[] = $row;
}

echo json_encode($invoices);
$conn->close();
?>