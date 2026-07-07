<?php

include 'conn.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
$entry_no = mysqli_real_escape_string($conn, $_POST['entry_no'] ?? '');
$source_id = mysqli_real_escape_string($conn, $_POST['source_id'] ?? '');
$call_by_id = mysqli_real_escape_string($conn, $_POST['call_by_id'] ?? '');
$date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');
$from = mysqli_real_escape_string($conn, $_POST['from'] ?? '');
$to = mysqli_real_escape_string($conn, $_POST['to'] ?? '');
$feedback = mysqli_real_escape_string($conn, $_POST['feedback'] ?? '');
$notes = mysqli_real_escape_string($conn, $_POST['notes'] ?? '');
$followupdate = mysqli_real_escape_string($conn, $_POST['followup_date'] ?? '');
$interest = mysqli_real_escape_string($conn, $_POST['interest'] ?? '');

if (
    empty($companyid) ||
    empty($entry_no) ||
    empty($source_id) ||
    empty($call_by_id) ||
    empty($date) ||
    empty($from)
) {
    echo json_encode([
        "status" => false,
        "message" => "Required fields missing"
    ]);
    exit();
}


$checkSql = "SELECT id
             FROM call_register
             WHERE entry_no='$entry_no' and companyid='$companyid'
             LIMIT 1";

$checkResult = mysqli_query($conn, $checkSql);

if (mysqli_num_rows($checkResult) > 0) {
    echo json_encode([
        "status" => false,
        "message" => "Entry number already exists"
    ]);
    exit();
}


$sql = "INSERT INTO call_register
(
    companyid,
    entry_no,
    source_id,
    call_by_id,
    date,
    `from`,
    `to`,
    feedback,
    notes,
    followup_date,
    interest
    
)
VALUES
(
    '$companyid',
    '$entry_no',
    '$source_id',
    '$call_by_id',
    '$date',
    '$from',
    '$to',
    '$feedback',
    '$notes',
    '$followupdate',
    '$interest'
   
)";

$result = mysqli_query($conn, $sql);

if ($result) {

    echo json_encode([
        "status" => true,
        "message" => "Call Register Added Successfully",
        "insert_id" => mysqli_insert_id($conn),


    ]);
} else {

    echo json_encode([
        "status" => false,
        "message" => mysqli_error($conn)
    ]);
}

mysqli_close($conn);
