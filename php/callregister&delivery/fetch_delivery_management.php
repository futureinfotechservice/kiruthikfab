<?php
include 'conn.php';
include 'cors.php';
// $json = file_get_contents('php://input');
// $obj = json_decode($json, true);

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

// $companyid = $obj['companyid'];
if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}
$sql = "SELECT * FROM delivery_head WHERE companyid = '$companyid' ORDER BY id DESC LIMIT 1";
$result = mysqli_query($conn, $sql);
$row = mysqli_fetch_assoc($result);
if ($row == null) {
    $sql = "SELECT distinct entry_no FROM delivery_head";
    $result = mysqli_query($conn, $sql);
    $details = [];
while($row = mysqli_fetch_assoc($result)){
    $details[] = $row;
}
    echo json_encode(["delivery_head" =>null,"other_entry_no" =>$details]);
    exit();
}
echo json_encode(["delivery_head" => $row]);
mysqli_close($conn);
?>