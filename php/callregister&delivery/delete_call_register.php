<?php

include 'conn.php';
include 'cors.php';

 
$id = mysqli_real_escape_string($conn, $_POST['id'] ?? '');

if (empty($id)) {
    echo json_encode([
        "status" => false,
        "message" => "ID is required"
    ]);
    exit();
}

$checkSql = "SELECT id FROM call_register WHERE id='$id' LIMIT 1";
$checkResult = mysqli_query($conn, $checkSql);

if (mysqli_num_rows($checkResult) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "Record not found"
    ]);
    exit();
}

$sql = "DELETE FROM call_register WHERE id='$id'";

if (mysqli_query($conn, $sql)) {
    echo json_encode([
        "status" => true,
        "message" => "Record deleted successfully"
    ]);
} else {
    echo json_encode([
        "status" => false,
        "message" => mysqli_error($conn)
    ]);
}

mysqli_close($conn);

?>