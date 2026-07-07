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
$sql = "SELECT Distinct invoiceno FROM invoice_head WHERE companyid = '$companyid' and ifnull(status,'pending') != 'delivered' ORDER BY invoiceno DESC";

$result = mysqli_query($conn, $sql);

$data = [];

while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}
echo json_encode(["invoice_no" => $data]);
mysqli_close($conn);
?>