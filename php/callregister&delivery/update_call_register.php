<?php

include 'conn.php';

include 'cors.php';
$id = mysqli_real_escape_string($conn, $_POST['id'] ?? '');

$source_id = mysqli_real_escape_string($conn, $_POST['source_id'] ?? '');
$call_by_id = mysqli_real_escape_string($conn, $_POST['call_by_id'] ?? '');

$date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');

$from = mysqli_real_escape_string($conn, $_POST['from'] ?? '');
$to = mysqli_real_escape_string($conn, $_POST['to'] ?? '');

$feedback = mysqli_real_escape_string($conn, $_POST['feedback'] ?? '');
$notes = mysqli_real_escape_string($conn, $_POST['notes'] ?? '');
$followup_date = mysqli_real_escape_string($conn, $_POST['followup_date'] ?? '');
$interest = mysqli_real_escape_string($conn, $_POST['interest'] ?? '');

if (
    empty($id) ||
    empty($source_id)

) {
    echo json_encode([
        "status" => false,
        "message" => "Required fields missing"
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

$sql = "
UPDATE call_register SET

source_id = '$source_id',
call_by_id = '$call_by_id',


 date = '$date',
`from` = '$from',
`to` = '$to',
feedback = '$feedback',
notes = '$notes',
followup_date = '$followup_date',
interest = '$interest'

WHERE id = '$id'
";
if ($call_by_id == 0) {
    $sql = "
UPDATE call_register SET

source_id = '$source_id',
feedback = '$feedback',
notes = '$notes',
followup_date = '$followup_date',
interest = '$interest'
date = '$date',

 `from` = '$from',
 `to` = '$to',
WHERE id = '$id'
";
}

if (mysqli_query($conn, $sql)) {

    echo json_encode([
        "status" => true,
        "message" => "Record updated successfully"
    ]);
} else {

    echo json_encode([
        "status" => false,
        "message" => mysqli_error($conn)
    ]);
}

mysqli_close($conn);
