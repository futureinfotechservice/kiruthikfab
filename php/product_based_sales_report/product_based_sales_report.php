<?php
require_once 'conn.php';

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Error reporting (disable in production)
error_reporting(E_ALL);
ini_set('display_errors', 0);

/**
 * Response helper function
 */
function sendResponse($status, $data = [], $message = '') {
    echo json_encode(array_merge([
        "status" => $status,
        "message" => $message
    ], $data));
    exit;
}

/**
 * Sanitize input
 */
function sanitizeInput($value) {
    if (is_array($value)) {
        return array_map('sanitizeInput', $value);
    }
    return htmlspecialchars(trim($value), ENT_QUOTES, 'UTF-8');
}

// Check database connection
if ($conn->connect_error) {
    sendResponse(false, [], "Database connection failed: " . $conn->connect_error);
}

// Get input data
try {
    $inputData = [];
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        
        if (strpos($contentType, 'application/json') !== false) {
            $json = file_get_contents('php://input');
            $inputData = json_decode($json, true) ?? [];
        } else {
            $inputData = $_POST;
        }
    } else {
        $inputData = $_GET;
    }
    
    // Sanitize all input
    $inputData = sanitizeInput($inputData);
    
} catch (Exception $e) {
    sendResponse(false, [], "Invalid input data");
}

// Extract parameters
$companyId   = $inputData['companyid'] ?? '';
$page        = max(1, (int)($inputData['page'] ?? 1));
$limit       = max(1, min((int)($inputData['limit'] ?? 100), 500));
$search      = $inputData['search'] ?? '';
$fromDate    = $inputData['from_date'] ?? '';
$toDate      = $inputData['to_date'] ?? '';
$source      = $inputData['source'] ?? '';
$product     = $inputData['product'] ?? '';
$salesPerson = $inputData['salesPerson'] ?? '';

// Validate required parameters
if (empty($companyId)) {
    sendResponse(false, [], "Company ID is required");
}

// Validate date format
if (!empty($fromDate) && !validateDate($fromDate)) {
    sendResponse(false, [], "Invalid from date format. Use YYYY-MM-DD");
}
if (!empty($toDate) && !validateDate($toDate)) {
    sendResponse(false, [], "Invalid to date format. Use YYYY-MM-DD");
}

// Validate date range
if (!empty($fromDate) && !empty($toDate) && $fromDate > $toDate) {
    sendResponse(false, [], "From date cannot be greater than to date");
}

/**
 * Validate date format (YYYY-MM-DD)
 */
function validateDate($date) {
    $d = DateTime::createFromFormat('Y-m-d', $date);
    return $d && $d->format('Y-m-d') === $date;
}

// Calculate offset
$offset = ($page - 1) * $limit;

// Build WHERE conditions
$whereConditions = ["h.companyid = ?"];
$params = [$companyId];
$types = "i";

// Add search condition
if (!empty($search)) {
    $whereConditions[] = "(
        h.invoiceno LIKE ? OR 
        c.name LIKE ? OR 
        sm.salespersonname LIKE ? OR 
        pm.productname LIKE ? OR 
        c.mobile_no LIKE ?
    )";
    $searchTerm = "%{$search}%";
    $params = array_merge($params, array_fill(0, 5, $searchTerm));
    $types .= "sssss";
}

// Add source filter
if (!empty($source)) {
    $whereConditions[] = "c.id = ?";
    $params[] = $source;
    $types .= "i";
}

// Add product filter
if (!empty($product)) {
    $whereConditions[] = "pm.id = ?";
    $params[] = $product;
    $types .= "i";
}

// Add sales person filter
if (!empty($salesPerson)) {
    $whereConditions[] = "sm.id = ?";
    $params[] = $salesPerson;
    $types .= "i";
}

// Add date range filter
if (!empty($fromDate) && !empty($toDate)) {
    $whereConditions[] = "DATE(h.date) BETWEEN ? AND ?";
    $params[] = $fromDate;
    $params[] = $toDate;
    $types .= "ss";
} elseif (!empty($fromDate)) {
    $whereConditions[] = "DATE(h.date) >= ?";
    $params[] = $fromDate;
    $types .= "s";
} elseif (!empty($toDate)) {
    $whereConditions[] = "DATE(h.date) <= ?";
    $params[] = $toDate;
    $types .= "s";
}

$whereClause = "WHERE " . implode(" AND ", $whereConditions);

// Build the base query
$baseSelect = "
    SELECT 
        h.id,
        h.invoiceno,
        h.customerid,
        c.name AS sourceName,
        c.mobile_no,
        h.date,
        h.grandtotal AS total,
        h.addedby,
        h.created_at,
        (SELECT COUNT(*) FROM invoice_detail WHERE headid = h.id) AS total_items,
        GROUP_CONCAT(DISTINCT pm.productname ORDER BY pm.productname SEPARATOR ', ') AS products,
        sm.salespersonname
    FROM invoice_head h
    LEFT JOIN sourcemaster c ON h.customerid = c.id
    LEFT JOIN salespersonmaster sm ON h.addedby = sm.id
    LEFT JOIN invoice_detail id ON h.id = id.headid
    LEFT JOIN productmaster pm ON id.productid = pm.id
    {$whereClause}
    GROUP BY h.id, h.invoiceno, h.customerid, c.name, c.mobile_no, h.date, h.grandtotal, h.addedby, h.created_at, sm.salespersonname
";

// Count query
$countSql = "
    SELECT COUNT(*) as total 
    FROM ({$baseSelect}) as subquery
";

$countStmt = mysqli_prepare($conn, $countSql);
if (!$countStmt) {
    sendResponse(false, [], "Count query preparation failed: " . mysqli_error($conn));
}

mysqli_stmt_bind_param($countStmt, $types, ...$params);
mysqli_stmt_execute($countStmt);
$countResult = mysqli_stmt_get_result($countStmt);
$totalRows = mysqli_fetch_assoc($countResult)['total'] ?? 0;
mysqli_stmt_close($countStmt);

// Main query with pagination
$sql = $baseSelect . " ORDER BY h.id DESC LIMIT ?, ?";
$params[] = $offset;
$params[] = $limit;
$types .= "ii";

$stmt = mysqli_prepare($conn, $sql);
if (!$stmt) {
    sendResponse(false, [], "Query preparation failed: " . mysqli_error($conn));
}

mysqli_stmt_bind_param($stmt, $types, ...$params);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

// Fetch and format data
$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Convert date strings
    if (!empty($row['date'])) {
        $row['date'] = date('Y-m-d H:i:s', strtotime($row['date']));
        $row['salesDate'] = date('Y-m-d', strtotime($row['date']));
    }
    if (!empty($row['created_at'])) {
        $row['created_at'] = date('Y-m-d H:i:s', strtotime($row['created_at']));
    }
    
    // Ensure products is a string
    $row['products'] = $row['products'] ?? '';
    
    // Add formatted qty if needed
    $row['qty'] = $row['total_items'] ?? 0;
    
    $data[] = $row;
}

mysqli_stmt_close($stmt);

 
sendResponse(true, [
     
    "page" => $page,
    "limit" => $limit,
    "total" => (int)$totalRows,
    "hasMore" => ($offset + $limit) < $totalRows,
    "totalPages" => ceil($totalRows / $limit),
    "data" => $data
]);

mysqli_close($conn);
