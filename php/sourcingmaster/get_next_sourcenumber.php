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

$query = "SELECT MAX(CAST(SUBSTRING_INDEX(source_no, '-', -1) AS UNSIGNED)) as max_no FROM sourcemaster WHERE companyid = '$companyid'";
$result = mysqli_query($conn, $query);
$row = mysqli_fetch_assoc($result);
$next_no = ($row['max_no'] ?? 0) + 1;
$source_no = "SRC-" . str_pad($next_no, 6, '0', STR_PAD_LEFT);

echo json_encode(["status" => "success", "source_no" => $source_no]);
mysqli_close($conn);
?>