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

if (!$obj) {
    echo json_encode(["success" => false, "message" => "Invalid JSON"]);
    exit;
}

$invoiceno = $obj["invoiceno"];
$companyid = $obj["companyid"];
$customerid = $obj["customerid"];
$date = $obj["date"];
$items = $obj["items"];
$remarks = $obj["remarks"];
$taxpercentage = $obj["taxpercentage"];
$subtotal = $obj["subtotal"];
$grandtotal = $obj["grandtotal"];
$addedby = $obj["addedby"];
$status = $obj["status"];

$conn->begin_transaction();

try {
    // Insert into invoice_head
    $stmt = $conn->prepare("
        INSERT INTO invoice_head (invoiceno, companyid, customerid, date, remarks, taxpercentage, subtotal, grandtotal, addedby, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->bind_param("siisssssss", $invoiceno, $companyid, $customerid, $date, $remarks, $taxpercentage, $subtotal, $grandtotal, $addedby, $status);
    $stmt->execute();

    $headid = $conn->insert_id;

    // Insert details
    $stmtDetail = $conn->prepare("
        INSERT INTO invoice_detail (companyid, headid, productid, modelid, sizeid, unitid, quantity, rate, amount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    foreach ($items as $item) {
        $productid = $item["productId"] ?? $item["productid"] ?? '0';
        $modelid = $item["modelId"] ?? $item["modelid"] ?? '0';
        $sizeid = $item["sizeId"] ?? $item["sizeid"] ?? '0';
        $unitid = $item["unitId"] ?? $item["unitid"] ?? '0';
        $quantity = $item["quantity"] ?? '1';
        $rate = $item["rate"] ?? '0';
        $amount = $item["amount"] ?? '0';

        $stmtDetail->bind_param("iiiiiiiss", $companyid, $headid, $productid, $modelid, $sizeid, $unitid, $quantity, $rate, $amount);
        
        if (!$stmtDetail->execute()) {
            throw new Exception("Detail insert failed: " . $stmtDetail->error);
        }
    }

    $conn->commit();
    echo json_encode(["success" => true, "message" => "Invoice saved successfully", "invoice_id" => $headid]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Invoice not saved", "error" => $e->getMessage()]);
}
?>