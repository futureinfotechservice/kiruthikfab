<?php
include 'conn.php';
include 'cors.php';
$companyid = $_POST['companyid']??'';
$interest = $_POST['interest']??"";


if (empty($companyid) || empty($interest)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit();
}

try {

    $interest1 = strtoupper($interest);
    $sql = "SELECT * FROM customer_interest_master
     where
   companyid='$companyid'and interest='$interest1'";

    $res = mysqli_query($conn, $sql);
    if ($res&&mysqli_num_rows($res)>0) {
        echo json_encode(["status" => "error", "message" => "Customer Interest  Already exists"]);
        exit();
    } else {
        $sql = "INSERT INTO customer_interest_master
    (companyid,interest)
    VALUES
    ('$companyid','$interest1' )";
        $res = mysqli_query($conn, $sql);

        if ($res) {
            echo json_encode(["status" => "success", "message" => "Customer Interest  created successfully"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
        }
    }
} catch (Exception $e) {

    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
mysqli_close($conn);
