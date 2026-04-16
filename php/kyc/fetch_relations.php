<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$relations = [
    ['id' => 'father', 'name' => 'Father'],
    ['id' => 'mother', 'name' => 'Mother'],
    ['id' => 'son', 'name' => 'Son'],
    ['id' => 'daughter', 'name' => 'Daughter'],
    ['id' => 'spouse', 'name' => 'Spouse'],
    ['id' => 'brother', 'name' => 'Brother'],
    ['id' => 'sister', 'name' => 'Sister'],
    ['id' => 'grandfather', 'name' => 'Grandfather'],
    ['id' => 'grandmother', 'name' => 'Grandmother']
];

echo json_encode(["status" => "success", "data" => $relations]);
mysqli_close($conn);
?>