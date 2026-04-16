<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

$sql = "SELECT id, productname as name FROM productmaster WHERE companyid = '$companyid' AND activestatus = '1' ORDER BY productname";
$result = mysqli_query($conn, $sql);

$products = [];
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $products[] = $row;
    }
}

echo json_encode(["status" => "success", "data" => $products]);
mysqli_close($conn);
?>