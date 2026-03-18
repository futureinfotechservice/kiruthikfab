<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed"]));
}

$json = file_get_contents('php://input');
$obj = json_decode($json, true);

$invoiceid = $obj['invoiceid'];
$companyid = $obj['companyid'];

$conn->begin_transaction();

try {
    // Delete details first
    $stmtDetail = $conn->prepare("DELETE FROM invoice_detail WHERE companyid = ? AND headid = ?");
    $stmtDetail->bind_param("ii", $companyid, $invoiceid);
    $stmtDetail->execute();

    // Delete head
    $stmtHead = $conn->prepare("DELETE FROM invoice_head WHERE companyid = ? AND id = ?");
    $stmtHead->bind_param("ii", $companyid, $invoiceid);
    $stmtHead->execute();

    $conn->commit();
    echo json_encode(["success" => true, "message" => "Deleted successfully"]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Delete failed", "error" => $e->getMessage()]);
}
?>