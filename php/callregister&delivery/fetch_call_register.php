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
$sql = "SELECT * FROM call_register WHERE companyid = '$companyid' ORDER BY id DESC LIMIT 1";
$result = mysqli_query($conn, $sql);
$row = mysqli_fetch_assoc($result);
if ($row == null) {
    $sql = "SELECT entry_no FROM call_register";
    $result = mysqli_query($conn, $sql);

    $data = [];

    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }

    echo json_encode([
        "call_register" => null,
        "other_entry_no" => $data
    ]);
    exit();
}
echo json_encode(["call_register" => $row]);
mysqli_close($conn);
?>