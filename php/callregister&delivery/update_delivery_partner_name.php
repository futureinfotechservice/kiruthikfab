<?php

include 'conn.php';

include 'cors.php';
$invoice_no  = $_POST['invoice_no'];
$partner_name = $_POST['partner_name'];

if (empty($invoice_no)) {
    echo json_encode([
        "status" => "error",
        "message" => "invoice_no Required"
    ]);
    exit();
}

$sql = "
UPDATE delivery_head
SET delivery_partner='$partner_name'
WHERE invoiceno='$invoice_no'
";

if (mysqli_query($conn, $sql)) {

    echo json_encode([
        "status" => "success",
        "message" => "Updated Successfully"
    ]);
} else {

    echo json_encode([
        "status" => "error",
        "message" => mysqli_error($conn)
    ]);
}
?>