<?php
include 'conn.php';
include 'cors.php';
$companyid = $_POST['companyid'] ?? "";

if (empty($companyid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing Company Id"
    ]);
    exit();
}

try {

    $sql = "SELECT id,interest FROM customer_interest_master
     where
   companyid='$companyid'";

    $res = mysqli_query($conn, $sql);
    $data = array();
    if (mysqli_num_rows($res) > 0) {
        while ($row = $res->fetch_assoc()) {
            $data[] = $row;
        }
        // echo json_encode(["status" => "success", "customer_interest_master" => $data]);
        echo json_encode($data);
        exit();
    } else {
        // echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
        echo json_encode($data);
    }
} catch (Exception $e) {
    echo json_encode([]);
    // echo json_encode([
    //     "status" => "error",
    //     "message" => $e->getMessage()
    // ]);
}
mysqli_close($conn);
