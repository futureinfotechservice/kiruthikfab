<?php
include 'conn.php';
include 'cors.php';
 
if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

// Read JSON Input
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

// Get Values
$companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
$fromDate  = mysqli_real_escape_string($conn, $obj['fromDate'] ?? '');
$toDate    = mysqli_real_escape_string($conn, $obj['toDate'] ?? '');

// Validation
if (empty($companyid) || empty($fromDate) || empty($toDate)) {
    echo json_encode([
        "status" => "error",
        "message" => "Company ID, From Date and To Date are required"
    ]);
    mysqli_close($conn);
    exit();
}

$sql = "
SELECT
    sm.id,
    sm.salespersonname,

    COALESCE(cr.totalCalls,0) AS totalCalls,
    COALESCE(cr.totalCalls,0) AS approach,
    COALESCE(km.kycFilled,0) AS kycFilled,
    COALESCE(cr.totalTime,0) AS totalTime,

    ROUND(
        COALESCE(cr.totalTime,0) * 100 / 480,
        2
    ) AS efficiency,

    ROUND(
        COALESCE(cr.totalTime,0) / 60,
        2
    ) AS hours,

    COALESCE(ih.totalProductSales,0) AS totalProductSales,

    ROUND(
        COALESCE(ih.totalProductSales,0) /
        NULLIF(COALESCE(cr.totalTime,0),0),
        2
    ) AS salesPerMin,

    ROUND(
        COALESCE(cr.totalTime,0) /
        NULLIF(COALESCE(km.kycFilled,0),0),
        2
    ) AS avgPerCustomer,

    COALESCE(ih.value,0) AS value,

    0 AS dayTotalOrder,
    0 AS dayTotalValue

FROM salespersonmaster sm

LEFT JOIN
(
    SELECT
        call_by_id,
        COUNT(*) AS totalCalls,
        COALESCE(
            SUM(
                TIMESTAMPDIFF(
                    MINUTE,
                    STR_TO_DATE(`from`, '%h:%i %p'),
                    STR_TO_DATE(`to`, '%h:%i %p')
                )
            ),
            0
        ) AS totalTime
    FROM call_register
    WHERE DATE(`date`) BETWEEN '$fromDate' AND '$toDate'
    GROUP BY call_by_id
) cr
ON sm.id = cr.call_by_id

LEFT JOIN
(
    SELECT
        addedby,
        COUNT(*) AS kycFilled
    FROM kyc_master
    WHERE DATE(created_at) BETWEEN '$fromDate' AND '$toDate'
    GROUP BY addedby
) km
ON CAST(sm.id AS CHAR) = km.addedby

LEFT JOIN
(
    SELECT
        addedby,
        COUNT(*) AS totalProductSales,
        COALESCE(SUM(grandtotal),0) AS value
    FROM invoice_head
    WHERE DATE(`date`) BETWEEN '$fromDate' AND '$toDate'
    GROUP BY addedby
) ih
ON sm.id = ih.addedby

WHERE sm.companyid = '$companyid'
AND sm.activestatus = 1

ORDER BY sm.salespersonname
";

$result = mysqli_query($conn, $sql);

if (!$result) {
    echo json_encode([
        "status" => "error",
        "message" => mysqli_error($conn),
        "sql" => $sql
    ]);
    exit();
}

$salespersons = [];

while ($row = mysqli_fetch_assoc($result)) {

    $salespersons[] = [
        'fromDate' => $fromDate,
        'toDate' => $toDate,

        'id' => $row['id'],
        'name' => $row['salespersonname'],

        'totalCalls' => (int)$row['totalCalls'],
        'approach' => (int)$row['approach'],
        'kycFilled' => (int)$row['kycFilled'],

        'totalTime' => (int)$row['totalTime'],

        'efficiency' => number_format((float)$row['efficiency'], 2),

        'hours' => (float)$row['hours'],

        'totalProductSales' => (int)$row['totalProductSales'],

        'salesPerMin' => $row['salesPerMin'] === null
            ? 0
            : number_format((float)$row['salesPerMin'], 2),

        'avgPerCustomer' => $row['avgPerCustomer'] === null
            ? 0
            : number_format((float)$row['avgPerCustomer'], 2),

        'value' => (float)$row['value'],

        'dayTotalOrder' => (int)$row['dayTotalOrder'],
        'dayTotalValue' => (int)$row['dayTotalValue']
    ];
}

echo json_encode([
    "status" => "success",
    "data" => $salespersons
]);

mysqli_close($conn);
?>