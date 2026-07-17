<?php
include 'conn.php';
include 'cors.php';

 if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed. Use POST."
    ]);
    exit();
}
$rawInput = file_get_contents('php://input');
if (empty($rawInput)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Empty request body"
    ]);
    exit();
}

$input = json_decode($rawInput, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid JSON format: " . json_last_error_msg()
    ]);
    exit();
}

$companyid = isset($input['companyid']) ? trim($input['companyid']) : '';
$search = isset($input['search']) ? trim($input['search']) : '';
$user_type = isset($input['user_type']) ? trim($input['user_type']) : '';
$user_id = isset($input['user_id']) ? trim($input['user_id']) : '';

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID is required"
    ]);
    exit();
}
$companyid = filter_var($companyid, FILTER_VALIDATE_INT);
if ($companyid === false || $companyid <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid Company ID format"
    ]);
    exit();
}
 
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

if (!empty($search)) {
  $searchSafe = '%' . addcslashes($search, '%_') . '%';
    $sql .= " AND (
        dd.entry_no LIKE ? 
        OR ih.invoiceno LIKE ? 
        OR ih.status LIKE ? 
        OR sm.name LIKE ?
        OR sm.address LIKE ?
    )";
   for ($i = 0; $i < 5; $i++) {
            $params[] = $searchSafe;
            $types .= "s";
        }
}

$sql .= " ORDER BY dd.id DESC LIMIT 10";

 
$stmt = mysqli_prepare($conn, $sql);
if (!$stmt) {
        throw new Exception("Database prepare failed: " . mysqli_error($conn));
    }
if (count($params) > 0) {
        mysqli_stmt_bind_param($stmt, $types, ...$params);
    }
    
    if (!mysqli_stmt_execute($stmt)) {
        throw new Exception("Query execution failed: " . mysqli_stmt_error($stmt));
    }
    
$result = mysqli_stmt_get_result($stmt);

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
   foreach ($row as $key => $value) {
            $row[$key] = htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
        }
        $data[] = $row;
}

 
echo json_encode([
    "status" => "success",
    "delivery_items" => $data,
     "count" => count($data)
]);

mysqli_stmt_close($stmt);
mysqli_close($conn);
 