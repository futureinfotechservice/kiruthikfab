<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$genders = [
    ['id' => 'male', 'name' => 'Male'],
    ['id' => 'female', 'name' => 'Female'],
    ['id' => 'other', 'name' => 'Other']
];

echo json_encode(["status" => "success", "data" => $genders]);
mysqli_close($conn);
?>