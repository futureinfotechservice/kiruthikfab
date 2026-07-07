<?php

include 'conn.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$companyid = $_POST['companyid'];
$call_by_id = $_POST['call_by_id'];


if (empty($companyid) || empty($call_by_id)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID and call_by_id are required"
    ]);
    exit();
}
$sql = "
SELECT
cr.id,
cr.entry_no,
DATE_FORMAT(cr.date,'%d/%m/%Y') date,
DATE_FORMAT(cr.followup_date,'%d/%m/%Y') followup_date,
cr.`from`,
cr.`to`,
s.name source_name,
st.salespersonname call_by,
cr.feedback,
cr.notes,
cim.id as interestid,
cim.companyid,
cim.interest

FROM call_register cr

LEFT JOIN sourcemaster s
ON s.id = cr.source_id

LEFT JOIN salespersonmaster st
ON st.id = cr.call_by_id

LEFT JOIN customer_interest_master cim
ON cim.id = cr.interest

WHERE cr.companyid='$companyid'and cr.call_by_id='$call_by_id'

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
