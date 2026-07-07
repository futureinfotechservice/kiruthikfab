<?php
include 'conn.php';
include 'cors.php';
$companyid = $_POST['companyid']??"";
$id = $_POST['id']??"";
if (empty($companyid) || empty($id)) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit();
}

try {

    $sql = "SELECT * FROM customer_interest_master
     where
   companyid='$companyid'and id='$id'";

    $res = mysqli_query($conn, $sql);
    if (mysqli_num_rows($res)<0) {
        echo json_encode(["status" => "error", "message" => "Customer Interest  not exists"]);
        exit();
    } else {
        $sql = "DELETE FROM customer_interest_master
    where
    id='$id'
    ";
        $res = mysqli_query($conn, $sql);

        if ($res) {
            echo json_encode(["status" => "success", "message" => "Customer Interest  deleted successfully"]);
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
