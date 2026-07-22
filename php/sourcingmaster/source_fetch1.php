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
$page = isset($_POST['page']) ? intval($_POST['page']) : 1;
$limit = isset($_POST['limit']) ? intval($_POST['limit']) : 50;
$search = $_POST['search'] ?? '';

$json = file_get_contents("php://input");
$obj = json_decode($json, true);

if (!empty($obj)) {
    $companyid = $obj['companyid'] ?? $companyid;
    $page = isset($obj['page']) ? intval($obj['page']) : $page;
    $limit = isset($obj['limit']) ? intval($obj['limit']) : $limit;
    $search = $obj['search'] ?? $search;
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
$search = mysqli_real_escape_string($conn, $search);

$where = "
sm.companyid='$companyid'
AND sm.activestatus='1'
";

if (!empty($search)) {
    $where .= " AND (
        sm.name LIKE '%$search%'
        OR sm.mobile_no LIKE '%$search%'
        OR sm.source_no LIKE '%$search%'
        OR sm.branch LIKE '%$search%'
    )";
}

/* total count */
$countSql = "SELECT COUNT(*) AS total
             FROM sourcemaster sm
             WHERE $where";

$countResult = mysqli_query($conn, $countSql);
$totalRows = mysqli_fetch_assoc($countResult)['total'];

/* paginated records */
$sql = "
SELECT 
    sm. id ,
    sm. companyid ,
    sm. source_no ,
    sm. source_date ,
    sm. gst_no ,
    sm. name ,
    sm. company_name ,
    sm. mobile_no ,
    sm. contact_no ,
    sm. whatsapp_no ,
    sm. area ,
    sm. area_id ,
    sm. address ,
    sm. occupation ,
    sm. occupation_id ,
    sm. refer_by ,
    sm. refer_by_id ,
    sm. agent ,
    sm. agent_id ,
    sm. sourcing_mode ,
    sm. sourcing_mode_id ,
    sm. entry_person ,
    sm. entry_person_id ,
    sm. background_network ,
    sm. customer_interest ,
    sm. notes ,
    sm. sales_person ,
    sm. sales_person_id ,
    sm. addedby ,
    sm. activestatus ,
    sm. created_at ,
    sm.branch ,
    dm. district_name as branch_name
FROM sourcemaster sm
left join district_master dm on sm.branch = dm.id
WHERE $where
ORDER BY sm.id DESC
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
    "total" => (int) $totalRows,
    "hasMore" => ($offset + $limit) < $totalRows,
    "data" => $data
]);

mysqli_close($conn);
