<?php

include 'conn.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$companyid = $_POST['companyid'];
$call_by_id = $_POST['call_by_id'];
$page      = isset($_POST['page']) ? (int)$_POST['page'] : 1;
$limit     = isset($_POST['limit']) ? (int)$_POST['limit'] : 100;

$search    = trim($_POST['search'] ?? '');
$fromDate  = trim($_POST['from_date'] ?? '');
$toDate    = trim($_POST['to_date'] ?? '');

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    exit();
}

$page = max(1, $page);
$limit = max(1, min($limit, 500));
$offset = ($page - 1) * $limit;
$companyid = mysqli_real_escape_string($conn, $companyid);
$call_by_id = mysqli_real_escape_string($conn, $call_by_id);
$where = "WHERE cr.companyid='$companyid'";
if (!empty($call_by_id)) {
    $where .= "and cr.call_by_id='$call_by_id'";
}
if (!empty($search)) {

    $search = mysqli_real_escape_string($conn, $search);

    $where .= "
    AND (
        s.name LIKE '%$search%'
        OR cr.entry_no LIKE '%$search%'
        OR st.salespersonname LIKE '%$search%'
        OR cim.interest LIKE '%$search%'
        OR s.mobile_no LIKE '%$search%'
    )
    ";
}
if (!empty($fromDate) && !empty($toDate)) {

    $fromDate = mysqli_real_escape_string($conn, $fromDate);
    $toDate   = mysqli_real_escape_string($conn, $toDate);

    $where .= "
    AND cr.date >= '$fromDate' 
AND cr.date <= '$toDate'
    
     
    ";
}

$countSql = "
SELECT COUNT(*) AS total

FROM call_register cr

LEFT JOIN sourcemaster s
ON s.id = cr.source_id

LEFT JOIN salespersonmaster st
ON st.id = cr.call_by_id

LEFT JOIN customer_interest_master cim
ON cim.id = cr.interest

$where
";
$countResult = mysqli_query($conn, $countSql);

$totalRows = 0;

if ($countResult) {
    $countRow = mysqli_fetch_assoc($countResult);
    $totalRows = (int)$countRow['total'];
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
s.mobile_no,
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

$where

ORDER BY cr.id DESC
LIMIT $offset, $limit
";

$result = mysqli_query($conn, $sql);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
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
