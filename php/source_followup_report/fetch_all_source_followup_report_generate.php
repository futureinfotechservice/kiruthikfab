<?php
include 'conn.php';
include 'cors.php';

header('Content-Type: application/json');

$companyid = $_POST['companyid'] ?? '';

if (empty($companyid)) {
    echo json_encode([
        "status" => false,
        "message" => "Company ID is required"
    ]);
    exit;
}

$where = " WHERE sm.companyid = ? ";
$params = [$companyid];
$types = "s";

/* ============================
   Total Count (Unique Sources)
   ============================ */

$countSql = "
SELECT COUNT(DISTINCT sm.id) AS total
FROM sourcemaster sm
LEFT JOIN salespersonmaster spm
    ON sm.sales_person_id = spm.id
LEFT JOIN call_register cr
    ON sm.id = cr.source_id
LEFT JOIN customer_interest_master cim
    ON cr.interest = cim.id
$where
";

$countStmt = mysqli_prepare($conn, $countSql);

if (!$countStmt) {
    echo json_encode([
        "status" => false,
        "message" => mysqli_error($conn)
    ]);
    exit;
}

mysqli_stmt_bind_param($countStmt, $types, ...$params);
mysqli_stmt_execute($countStmt);

$countResult = mysqli_stmt_get_result($countStmt);
$totalRows = mysqli_fetch_assoc($countResult)['total'] ?? 0;

mysqli_stmt_close($countStmt);

/* ============================
   Main Data
   ============================ */

$sql = "
SELECT
    sm.source_no,
    sm.name AS source_name,
    sm.mobile_no AS mobile,
    spm.salespersonname,
    cr.entry_no,
    cr.date,
    cr.`from`,
    cr.`to`,
    cr.followup_date,
    cr.interest AS interestid,
    cim.interest,
    cim.companyid,
    sm.source_date,

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

LEFT JOIN customer_interest_master cim
    ON cr.interest = cim.id

$where

ORDER BY sm.source_date DESC
";

$stmt = mysqli_prepare($conn, $sql);

if (!$stmt) {
    echo json_encode([
        "status" => false,
        "message" => mysqli_error($conn)
    ]);
    exit;
}

mysqli_stmt_bind_param($stmt, $types, ...$params);
mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

mysqli_stmt_close($stmt);
mysqli_close($conn);

echo json_encode([
    "status" => true,
    "message" => "Data fetched successfully",
    "page" => 1,
    "limit" => 0,
    "total" => (int)$totalRows,
    "hasMore" => false,
    "data" => $data
]);