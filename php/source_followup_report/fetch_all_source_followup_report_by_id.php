<?php

include 'conn.php';
include 'cors.php';

header('Content-Type: application/json');

$companyid = $_POST['companyid'] ?? '';
$id        = $_POST['id'] ?? '';

$page      = isset($_POST['page']) ? (int)$_POST['page'] : 1;
$limit     = isset($_POST['limit']) ? (int)$_POST['limit'] : 100;

$search    = trim($_POST['search'] ?? '');
$fromDate  = trim($_POST['from_date'] ?? '');
$toDate    = trim($_POST['to_date'] ?? '');

if (empty($companyid) || empty($id)) {
    echo json_encode([
        "status" => false,
        "message" => "Company ID and User ID are required"
    ]);
    exit;
}

$page = max(1, $page);
$limit = max(1, min($limit, 500));
$offset = ($page - 1) * $limit;

$companyid = mysqli_real_escape_string($conn, $companyid);
$id = mysqli_real_escape_string($conn, $id);

$where = "
WHERE sm.companyid = '$companyid'
AND sm.sales_person_id = '$id'
";

if (!empty($search)) {

    $search = mysqli_real_escape_string($conn, $search);

    $where .= "
    AND (
        sm.name LIKE '%$search%'
        OR sm.source_no LIKE '%$search%'
        OR spm.salespersonname LIKE '%$search%'
        OR cim.interest LIKE '%$search%'
        OR sm.mobile_no LIKE '%$search%'
        OR cr.entry_no LIKE '%$search%'
    )
    ";
}

if (!empty($fromDate) && !empty($toDate)) {

    $fromDate = mysqli_real_escape_string($conn, $fromDate);
    $toDate   = mysqli_real_escape_string($conn, $toDate);

    $where .= "
    AND DATE(cr.date)
    BETWEEN '$fromDate' AND '$toDate'
    ";
}

/* TOTAL COUNT */

$countSql = "
SELECT COUNT(*) AS total

FROM sourcemaster sm

LEFT JOIN salespersonmaster spm
ON sm.sales_person_id = spm.id

LEFT JOIN call_register cr
ON sm.id = cr.source_id

LEFT JOIN customer_interest_master cim
ON cr.interest = cim.id

$where
";

$countResult = mysqli_query($conn, $countSql);

$totalRows = 0;

if ($countResult) {
    $countRow = mysqli_fetch_assoc($countResult);
    $totalRows = (int)$countRow['total'];
}

/* MAIN DATA */

$sql = "
SELECT
    sm.source_no,
    sm.name AS source_name,
      sm.mobile_no as mobile,
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

GROUP BY
    sm.source_no,
    sm.name,
    spm.salespersonname,
    cr.entry_no,
    cr.date,
    cr.`from`,
    cr.`to`,
    cr.followup_date,
    cr.interest,
    sm.source_date

ORDER BY sm.source_date DESC

LIMIT $offset, $limit
";

$result = mysqli_query($conn, $sql);

$data = [];

if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
}

echo json_encode([
    "status" => true,
    "page" => $page,
    "limit" => $limit,
    "total" => $totalRows,
    "hasMore" => ($offset + $limit) < $totalRows,
    "data" => $data
]);

mysqli_close($conn);