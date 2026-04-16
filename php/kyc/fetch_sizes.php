<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$sizes = [
    ['id' => 'xs', 'name' => 'XS'],
    ['id' => 's', 'name' => 'S'],
    ['id' => 'm', 'name' => 'M'],
    ['id' => 'l', 'name' => 'L'],
    ['id' => 'xl', 'name' => 'XL'],
    ['id' => 'xxl', 'name' => 'XXL']
];

echo json_encode(["status" => "success", "data" => $sizes]);
mysqli_close($conn);
?>