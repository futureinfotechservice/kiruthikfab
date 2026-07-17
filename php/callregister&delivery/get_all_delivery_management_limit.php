  <?php
    include 'conn.php';

    include 'cors.php';
    $companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

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
    $where = "WHERE dh.companyid = '$companyid'";
    if (!empty($search)) {

        $search = mysqli_real_escape_string($conn, $search);

        $where .= "
    AND (
        dh.invoiceno LIKE '%$search%'
        OR dh.entry_no LIKE '%$search%'
         
    )
    ";
    }
    if (!empty($fromDate) && !empty($toDate)) {

        $fromDate = mysqli_real_escape_string($conn, $fromDate);
        $toDate   = mysqli_real_escape_string($conn, $toDate);

        $where .= "
    AND dd.date >= '$fromDate' 
AND dd.date <= '$toDate'
    
     
    ";
    }
    $countSql = "
SELECT
    COUNT(*) AS total

FROM delivery_head dh
INNER JOIN delivery_details dd
    ON dh.id = dd.head_id
LEFT JOIN invoice_head ih
    ON dh.invoiceno = ih.invoiceno
    AND dh.companyid = ih.companyid
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
    dh.id AS headid,
    dh.invoiceno,
    dh.entry_no,
    dh.companyid,
    dd.id AS detailid,
    dd.checklist,
    dd.isChecked,
    dd.date,
    ih.status AS invoice_status
FROM delivery_head dh
INNER JOIN delivery_details dd
    ON dh.id = dd.head_id
LEFT JOIN invoice_head ih
    ON dh.invoiceno = ih.invoiceno
    AND dh.companyid = ih.companyid
$where
ORDER BY dd.id ASC
LIMIT $offset, $limit;
";

    $result = mysqli_query($conn, $sql);

    $data = [];

    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }

    echo json_encode([
        "status" => "success",
        "page" => $page,
        "limit" => $limit,
        "total" => $totalRows,
        "hasMore" => ($offset + $limit) < $totalRows,
        "delivery_items" => $data
    ]);

    mysqli_close($conn);
    ?>
