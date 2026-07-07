<?php

include 'conn.php';
include 'cors.php';

$companyid = $_POST['companyid'];
$id = $_POST['id'];


if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    exit();
}
$sql = "
SELECT
    sm.source_no,
    sm.name AS source_name,
    sm.mobile_no AS mobile,
    spm.salespersonname,
    cr.id,
    cr.entry_no,
    cr.date,
    cr.`from`,
    cr.`to`,
    cr.followup_date,
    cr.interest AS interestid,
    cr.feedback,
    cr.notes,
    cr.call_by_id,
    cim.interest,
    cim.companyid,
    sm.source_date,
    spms.salespersonname AS call_by,
    COALESCE(
        TIMESTAMPDIFF(
            MINUTE,
            STR_TO_DATE(cr.`from`, '%h:%i %p'),
            STR_TO_DATE(cr.`to`, '%h:%i %p')
        ),
        0
    ) AS totalTime
FROM sourcemaster sm

LEFT JOIN salespersonmaster spm
    ON sm.sales_person_id = spm.id

LEFT JOIN call_register cr
    ON sm.id = cr.source_id

LEFT JOIN salespersonmaster spms
    ON cr.call_by_id = spms.id

LEFT JOIN customer_interest_master cim
    ON cr.interest = cim.id

WHERE sm.companyid = '$companyid'
  AND sm.id = '$id'
ORDER BY cr.id DESC
";

$result = mysqli_query($conn, $sql);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

echo json_encode([
    "status" => true,
    "data" => $data
]);
mysqli_close($conn);
