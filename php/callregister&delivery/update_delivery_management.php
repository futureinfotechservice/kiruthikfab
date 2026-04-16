<?php
include 'conn.php';

include 'cors.php';
$companyid = mysqli_real_escape_string($conn, $_POST['companyid']);
$headid    = mysqli_real_escape_string($conn, $_POST['headid']);
$status    = mysqli_real_escape_string($conn, $_POST['status']);

if (empty($companyid) || empty($headid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Required fields missing"
    ]);
    exit();
}

$sql = "
UPDATE invoice_head
SET status='$status'
WHERE invoiceno='$headid'
AND companyid='$companyid'
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

mysqli_close($conn);
?>