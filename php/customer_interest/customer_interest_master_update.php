<?php
include 'conn.php';
include 'cors.php';
$companyid = $_POST['companyid'] ?? '';
$id = $_POST['id'] ?? '';
$interest = $_POST['interest'] ?? "";


if (empty($companyid) || empty($interest) || empty($id)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit();
}

try {
    $sql = "SELECT * FROM customer_interest_master
     where
  id='$id'";

    $res = mysqli_query($conn, $sql);

    if (mysqli_num_rows($res) <= 0) {
        echo json_encode(["status" => "error", "message" => "Customer Interest  not exists"]);
        exit();
    } else {
        $interest= strtoupper($interest);
        $sql = "UPDATE  customer_interest_master
        SET
    interest='$interest' where (id='$id')";
        $res = mysqli_query($conn, $sql);

        if ($res) {
            echo json_encode(["status" => "success", "message" => "Customer Interest  updated successfully"]);
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
