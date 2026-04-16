<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$sql = "SELECT id, district_name as name FROM district_master ORDER BY district_name";
$result = mysqli_query($conn, $sql);

$districts = [];
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $districts[] = $row;
    }
}

echo json_encode(["status" => "success", "data" => $districts]);
mysqli_close($conn);
?>