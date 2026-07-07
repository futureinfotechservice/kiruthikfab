<?php
include 'conn.php';
include 'cors.php';
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$user_type = isset($_POST['user_type']) ? mysqli_real_escape_string($conn, $_POST['user_type']) : '';
$user_id = isset($_POST['user_id']) ? mysqli_real_escape_string($conn, $_POST['user_id']) : '';
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj) && isset($obj['companyid'])) {
    $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}
if (strtoupper($user_type) == "ADMIN") {
    $sql = "SELECT
        sm.id,
        sm.salespersonname,

        COALESCE(cr.totalCalls,0) totalCalls,
        COALESCE(cr.totalCalls,0) approach,

        COALESCE(km.kycFilled,0) kycFilled,

        COALESCE(cr.totalTime,0) totalTime,

        ROUND(
            COALESCE(cr.totalTime,0) * 100 / 480,
            2
        ) AS efficiency 
        -- ,

        -- ROUND(
        --     COALESCE(cr.totalTime,0) / 60,
        --     2
        -- ) AS hours,

        -- COALESCE(ih.totalProductSales,0) totalProductSales,

        -- ROUND(
        --     COALESCE(ih.totalProductSales,0) /
        --     NULLIF(COALESCE(cr.totalTime,0),0),
        --     2
        -- ) AS salesPerMin,

        -- ROUND(
        --     COALESCE(cr.totalTime,0) /
        --     NULLIF(COALESCE(km.kycFilled,0),0),
        --     2
        -- ) AS avgPerCustomer,

        -- COALESCE(ih.value,0) value,

        -- 0 AS dayTotalOrder,
        -- 0 AS dayTotalValue

    FROM salespersonmaster sm

    LEFT JOIN
    (
        SELECT
            call_by_id,
            COUNT(*) totalCalls,
            SUM(
                TIMESTAMPDIFF(
                    MINUTE,
                    STR_TO_DATE(`from`,'%h:%i %p'),
                    STR_TO_DATE(`to`,'%h:%i %p')
                )
            ) totalTime
        FROM call_register
        GROUP BY call_by_id
    ) cr ON sm.id = cr.call_by_id

    LEFT JOIN
    (
        SELECT
            addedby,
            COUNT(*) kycFilled
        FROM kyc_master
        GROUP BY addedby
    ) km ON CAST(sm.id AS CHAR) = km.addedby

    LEFT JOIN
    (
        SELECT
            addedby,
            COUNT(*) totalProductSales,
            SUM(grandtotal) value
        FROM invoice_head
        GROUP BY addedby
    ) ih ON sm.id = ih.addedby

    WHERE sm.companyid = '$companyid'
    AND sm.activestatus = 1

    ORDER BY sm.salespersonname;";

    $result = mysqli_query($conn, $sql);

    $salespersons = [];
    if (mysqli_num_rows($result) > 0) {
        while ($row = mysqli_fetch_assoc($result)) {
            $salespersons[] = [
                'id' => $row['id'],
                'name' => $row['salespersonname'],
                'totalCalls' => $row['totalCalls'] == null ? 0 : $row['totalCalls'],
                'approach' => $row['approach'] == null ? 0 : $row['approach'],
                'kycFilled' => $row['kycFilled'] == null ? 0 : $row['kycFilled'],
                'totalTime' => $row['totalTime'] == null ? 0 : ($row['totalTime']),
                'efficiency' => $row['efficiency'] == null ? 0 : number_format($row['efficiency'], 2) //,
                // 'hours' => $row['totalTime'] == null ? 0 : ($row['totalTime'] / 60),
                // 'totalProductSales' => $row['totalProductSales'] == null ? 0 : $row['totalProductSales'],
                // 'salesPerMin' => $row['salesPerMin'] == null ? 0 : number_format($row['salesPerMin'], 2),
                // 'avgPerCustomer' => $row['avgPerCustomer'] == null ? 0 : number_format($row['avgPerCustomer'], 2),
                // 'value' => $row['value'] == null ? 0 : intval($row['value']),
                // 'dayTotalOrder' => $row['dayTotalOrder'] == null ? 0 : $row['dayTotalOrder'],
                // 'dayTotalValue' => $row['dayTotalValue'] == null ? 0 : $row['dayTotalValue']

            ];
        }
    }

    echo json_encode(["status" => "success", "data" => $salespersons]);
} else {
    $sql = "SELECT
        sm.id,
        sm.salespersonname,

        COALESCE(cr.totalCalls,0) totalCalls,
        COALESCE(cr.totalCalls,0) approach,

        COALESCE(km.kycFilled,0) kycFilled,

        COALESCE(cr.totalTime,0) totalTime,

        ROUND(
            COALESCE(cr.totalTime,0) * 100 / 480,
            2
        ) AS efficiency 
        -- ,

        -- ROUND(
        --     COALESCE(cr.totalTime,0) / 60,
        --     2
        -- ) AS hours,

        -- COALESCE(ih.totalProductSales,0) totalProductSales,

        -- ROUND(
        --     COALESCE(ih.totalProductSales,0) /
        --     NULLIF(COALESCE(cr.totalTime,0),0),
        --     2
        -- ) AS salesPerMin,

        -- ROUND(
        --     COALESCE(cr.totalTime,0) /
        --     NULLIF(COALESCE(km.kycFilled,0),0),
        --     2
        -- ) AS avgPerCustomer,

        -- COALESCE(ih.value,0) value,

        -- 0 AS dayTotalOrder,
        -- 0 AS dayTotalValue

    FROM salespersonmaster sm

    LEFT JOIN
    (
        SELECT
            call_by_id,
            COUNT(*) totalCalls,
            SUM(
                TIMESTAMPDIFF(
                    MINUTE,
                    STR_TO_DATE(`from`,'%h:%i %p'),
                    STR_TO_DATE(`to`,'%h:%i %p')
                )
            ) totalTime
        FROM call_register
        GROUP BY call_by_id
    ) cr ON sm.id = cr.call_by_id

    LEFT JOIN
    (
        SELECT
            addedby,
            COUNT(*) kycFilled
        FROM kyc_master
        GROUP BY addedby
    ) km ON CAST(sm.id AS CHAR) = km.addedby

    LEFT JOIN
    (
        SELECT
            addedby,
            COUNT(*) totalProductSales,
            SUM(grandtotal) value
        FROM invoice_head
        GROUP BY addedby
    ) ih ON sm.id = ih.addedby

    WHERE sm.companyid = '$companyid'
    AND sm.activestatus = 1
    and sm.id='$user_id'

    ORDER BY sm.salespersonname;";

    $result = mysqli_query($conn, $sql);

    $salespersons = [];
    if (mysqli_num_rows($result) > 0) {
        while ($row = mysqli_fetch_assoc($result)) {
            $salespersons[] = [
                'id' => $row['id'],
                'name' => $row['salespersonname'],
                'totalCalls' => $row['totalCalls'] == null ? 0 : $row['totalCalls'],
                'approach' => $row['approach'] == null ? 0 : $row['approach'],
                'kycFilled' => $row['kycFilled'] == null ? 0 : $row['kycFilled'],
                'totalTime' => $row['totalTime'] == null ? 0 : ($row['totalTime']),
                'efficiency' => $row['efficiency'] == null ? 0 : number_format($row['efficiency'], 2) //,
                // 'hours' => $row['totalTime'] == null ? 0 : ($row['totalTime'] / 60),
                // 'totalProductSales' => $row['totalProductSales'] == null ? 0 : $row['totalProductSales'],
                // 'salesPerMin' => $row['salesPerMin'] == null ? 0 : number_format($row['salesPerMin'], 2),
                // 'avgPerCustomer' => $row['avgPerCustomer'] == null ? 0 : number_format($row['avgPerCustomer'], 2),
                // 'value' => $row['value'] == null ? 0 : intval($row['value']),
                // 'dayTotalOrder' => $row['dayTotalOrder'] == null ? 0 : $row['dayTotalOrder'],
                // 'dayTotalValue' => $row['dayTotalValue'] == null ? 0 : $row['dayTotalValue']

            ];
        }
    }

    echo json_encode(["status" => "success", "data" => $salespersons]);
}
mysqli_close($conn);
