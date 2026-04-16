<?php

include 'conn.php';

include 'cors.php';
$id = mysqli_real_escape_string($conn, $_POST['id'] ?? '');

$source_id = mysqli_real_escape_string($conn, $_POST['source_id'] ?? '');
$call_by_id = mysqli_real_escape_string($conn, $_POST['call_by_id'] ?? '');

// $date = mysqli_real_escape_string($conn, $_POST['date'] ?? '');

// $from = mysqli_real_escape_string($conn, $_POST['from'] ?? '');
// $to = mysqli_real_escape_string($conn, $_POST['to'] ?? '');

$feedback = mysqli_real_escape_string($conn, $_POST['feedback'] ?? '');
$notes = mysqli_real_escape_string($conn, $_POST['notes'] ?? '');

if (
    empty($id) ||
    empty($source_id) ||
    empty($call_by_id) 
    // empty($date) ||
    // empty($from)
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
// date = '$date',

// `from` = '$from',
// `to` = '$to',
$sql = "
UPDATE call_register SET

source_id = '$source_id',
call_by_id = '$call_by_id',



feedback = '$feedback',
notes = '$notes'

WHERE id = '$id'
";

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

?>