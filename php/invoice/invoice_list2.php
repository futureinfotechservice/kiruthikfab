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

$sql = "SELECT i.id, i.invoiceno, i.customerid, i.date, i.remarks, 
        i.taxpercentage, i.subtotal, i.grandtotal, i.addedby, i.created_at,i.packing_amount,
        IFNULL(c.name,'') as customername, c.mobile_no  as customerphone, 
        -- ifnull(c.gst_no,0) as gst_no,
        ifnull(i.gst_no,0) as gst_no,
         c.address, c.area,
        (SELECT COUNT(*) FROM invoice_detail WHERE headid = i.id) as total_items,
        i.delivery_partner,
        d.name as delivery_partner_name
        FROM invoice_head i
        LEFT JOIN sourcemaster c ON i.customerid = c.id
        LEFT JOIN delivery_person_master d ON i.delivery_partner = d.id
        WHERE i.companyid = '$companyid'
        ORDER BY i.id DESC";

$result = $conn->query($sql);
$invoices = [];

while ($row = $result->fetch_assoc()) {
    $invoices[] = $row;
}

echo json_encode($invoices);
$conn->close();
