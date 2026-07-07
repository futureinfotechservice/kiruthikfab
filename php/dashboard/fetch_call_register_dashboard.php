<?php
include 'conn.php';
include 'cors.php';

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$search    = trim($_POST['search'] ?? '');
$user_type    = trim($_POST['user_type'] ?? '');
$user_id    = trim($_POST['user_id'] ?? '');

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

$where = "WHERE cr.companyid = '$companyid'";

if (!empty($user_type) && !empty($user_id)) {
    if (strtoupper($user_type) != 'ADMIN') {
        $where .= " AND cr.call_by_id = '$user_id'";
    }
}

if (!empty($search)) {
    $search = mysqli_real_escape_string($conn, $search);
    $where .= "
    AND (
        cr.entry_no LIKE '%$search%'
        OR sm.name LIKE '%$search%'
        OR spm.salespersonname LIKE '%$search%'
        OR sm.mobile_no LIKE '%$search%'
    )";
}

$sql = "SELECT 
    cr.entry_no,
    cr.source_id,
    cr.call_by_id,
    cr.date, 
    sm.name AS source_name,
    spm.salespersonname AS call_by_name,
    sm.mobile_no as mobile
FROM call_register cr
LEFT JOIN sourcemaster sm ON cr.source_id = sm.id
LEFT JOIN salespersonmaster spm ON cr.call_by_id = spm.id
$where 
ORDER BY cr.id DESC 
LIMIT 10";

$result = mysqli_query($conn, $sql);

// Check for query errors
if (!$result) {
    echo json_encode([
        "status" => "error",
        "message" => "Query failed: " . mysqli_error($conn)
    ]);
    mysqli_close($conn);
    exit();
}

// Fetch ALL rows (not just one)
$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

echo json_encode([
    "status" => "success",
    "call_register" => $data,
    "total" => count($data)
]);

mysqli_close($conn);
?>