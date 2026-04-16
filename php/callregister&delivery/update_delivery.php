<?php

include 'conn.php';

include 'cors.php';
$detailid  = $_POST['detailid'];
$isChecked = $_POST['isChecked'];

if (empty($detailid)) {
    echo json_encode([
        "status" => "error",
        "message" => "Detail ID Required"
    ]);
    exit();
}

$sql = "
UPDATE delivery_details
SET isChecked='$isChecked'
WHERE id='$detailid'
";

if (mysqli_query($conn, $sql)) {

    echo json_encode([
        "status" => "success",
        "message" => "Updated Successfully"
    ]);
} else {

    echo json_encode([
        "status" => "error",
        "message" => mysqli_error($conn)
    ]);
}
?>