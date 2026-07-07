<?php
include 'conn.php';
include 'cors.php';

header('Content-Type: application/json');

$companyid = $_POST['companyid'] ?? '';
$page      = (int)($_POST['page'] ?? 1);
$limit     = (int)($_POST['limit'] ?? 100);
$search    = trim($_POST['search'] ?? '');
$fromDate  = trim($_POST['from_date'] ?? '');
$toDate    = trim($_POST['to_date'] ?? '');

if (empty($companyid)) {
    echo json_encode([
        "status" => false,
        "message" => "Company ID is required"
    ]);
    exit;
}

$page = max(1, $page);
$limit = max(1, min($limit, 500));
$offset = ($page - 1) * $limit;

$where = " WHERE sm.companyid = ? 
AND (
    cr.entry_no IS NULL
    OR TRIM(cr.entry_no) = ''
)";

$params = [$companyid];
$types = "s";

if (!empty($search)) {
    $where .= " AND (
        sm.name LIKE ?
        OR sm.source_no LIKE ?
        OR spm.salespersonname LIKE ?
        OR cim.interest LIKE ?
         OR sm.mobile_no LIKE ?
        OR cr.entry_no LIKE ?
    )";

    $searchValue = "%{$search}%";

    $params[] = $searchValue;
    $params[] = $searchValue;
    $params[] = $searchValue;
    $params[] = $searchValue;
    $params[] = $searchValue;
    $params[] = $searchValue;

    $types .= "ssssss";
}

if (!empty($fromDate) && !empty($toDate)) {
    $where .= " AND DATE(cr.date) BETWEEN ? AND ?";
    $params[] = $fromDate;
    $params[] = $toDate;
    $types .= "ss";
}

/* Total Count */

$countSql = "
SELECT COUNT(*) as total
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
mysqli_stmt_bind_param($countStmt, $types, ...$params);
mysqli_stmt_execute($countStmt);

$countResult = mysqli_stmt_get_result($countStmt);
$totalRows = mysqli_fetch_assoc($countResult)['total'];

/* Main Data */

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
    cr.interest as interestid,
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

LIMIT ?, ?
";

$params[] = $offset;
$params[] = $limit;
$types .= "ii";

$stmt = mysqli_prepare($conn, $sql);
mysqli_stmt_bind_param($stmt, $types, ...$params);

mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

echo json_encode([
    "status" => true,
    "page" => $page,
    "limit" => $limit,
    "total" => (int)$totalRows,
    "hasMore" => ($offset + $limit) < $totalRows,
    "data" => $data
]);

mysqli_close($conn);
