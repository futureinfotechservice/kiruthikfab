<?php

include 'conn.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Connection failed"
    ]));
}

$companyid = $_POST['companyid'] ?? '';
$page      = isset($_POST['page']) ? intval($_POST['page']) : 1;
$limit     = isset($_POST['limit']) ? intval($_POST['limit']) : 50;
$search    = $_POST['search'] ?? '';

$json = file_get_contents("php://input");
$obj = json_decode($json, true);

if (!empty($obj)) {
    $companyid = $obj['companyid'] ?? $companyid;
    $page      = isset($obj['page']) ? intval($obj['page']) : $page;
    $limit     = isset($obj['limit']) ? intval($obj['limit']) : $limit;
    $search    = $obj['search'] ?? $search;
}

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID required"
    ]);
    exit;
}

$offset = ($page - 1) * $limit;

$companyid = mysqli_real_escape_string($conn, $companyid);
$search    = mysqli_real_escape_string($conn, $search);

$where = "
companyid='$companyid'
AND activestatus='1'
";

if (!empty($search)) {
    $where .= " AND (
        name LIKE '%$search%'
        OR mobile_no LIKE '%$search%'
        OR source_no LIKE '%$search%'
        OR branch LIKE '%$search%'
    )";
}

/* total count */
$countSql = "SELECT COUNT(*) AS total
             FROM sourcemaster
             WHERE $where";

$countResult = mysqli_query($conn, $countSql);
$totalRows = mysqli_fetch_assoc($countResult)['total'];

/* paginated records */
$sql = "
SELECT *
FROM sourcemaster
WHERE $where
ORDER BY id DESC
LIMIT $limit OFFSET $offset
";

$result = mysqli_query($conn, $sql);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {

    if (!empty($row['source_date'])) {
        $date = new DateTime($row['source_date']);
        $row['source_date_display'] =
            $date->format('d/m/Y');
    }

    $data[] = $row;
}

echo json_encode([
    "page" => $page,
    "limit" => $limit,
    "total" => (int)$totalRows,
    "hasMore" => ($offset + $limit) < $totalRows,
    "data" => $data
]);

mysqli_close($conn);
