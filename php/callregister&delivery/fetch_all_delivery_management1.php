<?php
include 'conn.php';
include 'cors.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$bill_no = isset($_POST['invoice_no']) ? mysqli_real_escape_string($conn, $_POST['invoice_no']) : '';

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    exit();
}


$sql = "
SELECT
    dh.id AS headid,
    dh.invoiceno,
    dh.entry_no,
    dh.companyid,
    dh.delivery_partner,
    dd.id AS detailid,
    dd.checklist,
    dd.isChecked,
    dd.date,
    ih.status AS invoice_status,
    ih.delivery_partner as invoice_delivery_partner
FROM delivery_head dh
INNER JOIN delivery_details dd
    ON dh.id = dd.head_id
LEFT JOIN invoice_head ih
    ON dh.invoiceno = ih.invoiceno
    AND dh.companyid = ih.companyid
WHERE dh.companyid = '$companyid'
  AND dh.invoiceno = '$bill_no'
ORDER BY dd.id ASC;
";

$result = mysqli_query($conn, $sql);

$data = [];
$data1 = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}
if (empty($data)) {
    $sql = "
  SELECT
    delivery_partner as invoice_delivery_partner
FROM invoice_head
WHERE  companyid = '$companyid'
  AND  invoiceno = '$bill_no'

";
$result = mysqli_query($conn, $sql);



while ($row = mysqli_fetch_assoc($result)) {
    $data1[] = $row;
}
}

echo json_encode([
    "status" => "success",
    "delivery_items" => $data,
    "delivery_items1" => $data1
]);

mysqli_close($conn);
?>