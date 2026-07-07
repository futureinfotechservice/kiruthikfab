<?php
include 'conn.php';
include 'cors.php';


$companyid = $_POST['companyid'];
$invoiceno = $_POST['invoiceno'];
$entry_no  = $_POST['entry_no'];
$delivery_partner  = $_POST['delivery_partner'];

if (empty($companyid) || empty($invoiceno) || empty($entry_no)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit();
}

$checklists = [
    'INVOICE_NO',
    'PAYMENT_RECEIVED',
    'HAND_STOCK_TO_DELIVERY_AREA',
    'PACKAGE_COMPLETE',
    'DELIVERY_PARTNER',
    'CUSTOMER_RECEIVED'

];

mysqli_begin_transaction($conn);

try {

    $sql = "INSERT INTO delivery_head
    (companyid,entry_no,invoiceno,delivery_partner)
    VALUES
    ('$companyid','$entry_no','$invoiceno','$delivery_partner')";

    mysqli_query($conn, $sql);

    $head_id = mysqli_insert_id($conn);

    foreach ($checklists as $checklist) {

        $sql2 = "
        INSERT INTO delivery_details
        (head_id,checklist,date,isChecked)
        VALUES
        (
            '$head_id',
            '$checklist',
            CURDATE(),
            0
        )";

        mysqli_query($conn, $sql2);
    }

    mysqli_commit($conn);

    echo json_encode([
        "status" => "success",
        "head_id" => $head_id
    ]);
} catch (Exception $e) {

    mysqli_rollback($conn);

    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
