<?php
include 'conn.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$companyid = isset($_POST['companyid']) ? trim($_POST['companyid']) : '';
$search    = trim($_POST['search'] ?? '');
$user_type    = trim($_POST['user_type'] ?? '');
$user_id    = trim($_POST['user_id'] ?? '');

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    exit();
}

// Build the base query
$sql = "
SELECT
    dd.id AS headid,
    dd.entry_no,
    dd.invoiceno,
    ih.status,
    ih.date,
    ih.customerid,
    sm.name AS customer_name,
    sm.address  
FROM delivery_head dd
LEFT JOIN invoice_head ih
    ON dd.invoiceno = ih.invoiceno
   AND dd.companyid = ih.companyid
LEFT JOIN sourcemaster sm
    ON ih.customerid = sm.id
WHERE dd.companyid = ?";

$params = [$companyid];
$types = "i";

// Add search condition if provided
if (!empty($search)) {
    $searchParam = "%$search%";
    $sql .= " AND (
        dd.entry_no LIKE ? 
        OR ih.invoiceno LIKE ? 
        OR ih.status LIKE ? 
        OR sm.name LIKE ?
        OR sm.address LIKE ?
    )";
    $params[] = $searchParam;
    $params[] = $searchParam;
    $params[] = $searchParam;
    $params[] = $searchParam;
    $params[] = $searchParam;
    $types .= "sssss";
}

$sql .= " ORDER BY dd.id DESC LIMIT 10";

// Prepare and execute
$stmt = mysqli_prepare($conn, $sql);
mysqli_stmt_bind_param($stmt, $types, ...$params);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

// Optional: Reverse to get ascending order (oldest first among last 10)
//  $data = array_reverse($data);

echo json_encode([
    "status" => "success",
    "delivery_items" => $data
]);

mysqli_stmt_close($stmt);
mysqli_close($conn);
?>