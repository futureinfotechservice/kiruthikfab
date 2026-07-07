<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

// Get JSON input
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!$obj) {
    echo json_encode(["success" => false, "message" => "Invalid JSON"]);
    exit;
}

// Extract header fields
$invoiceid   = $obj["invoiceid"];
$invoiceno   = $obj["invoiceno"];
$companyid   = $obj["companyid"];
$customerid  = $obj["customerid"];
$date        = $obj["date"];
$items       = $obj["items"];
$remarks     = $obj["remarks"];
$taxpercentage = $obj["taxpercentage"];
$subtotal    = $obj["subtotal"];
$grandtotal  = $obj["grandtotal"];
$packing_amount  = $obj["packing_amount"];

// Begin transaction
$conn->begin_transaction();

try {
    // Update invoice_head
    $stmt = $conn->prepare("
        UPDATE invoice_head 
        SET invoiceno = ?, 
            customerid = ?, 
            date = ?, 
            remarks = ?, 
            taxpercentage = ?, 
            subtotal = ?, 
            grandtotal = ?,
            packing_amount=?

        WHERE id = ? AND companyid = ?
    ");

    $stmt->bind_param(
        "sisssssiii",
        $invoiceno,
        $customerid,
        $date,
        $remarks,
        $taxpercentage,
        $subtotal,
        $grandtotal,
        $packing_amount,
        $invoiceid,
        $companyid
    );

    if (!$stmt->execute()) {
        throw new Exception("Failed to update invoice head: " . $stmt->error);
    }

    // Delete existing details
    $stmtDelete = $conn->prepare("DELETE FROM invoice_detail WHERE headid = ? AND companyid = ?");
    $stmtDelete->bind_param("ii", $invoiceid, $companyid);

    if (!$stmtDelete->execute()) {
        throw new Exception("Failed to delete existing details: " . $stmtDelete->error);
    }

    // Insert new details
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

        $stmtDetail->bind_param(
            "iiiiiiiss",
            $companyid,
            $invoiceid,
            $productid,
            $modelid,
            $sizeid,
            $unitid,
            $quantity,
            $rate,
            $amount
        );

        if (!$stmtDetail->execute()) {
            throw new Exception("Failed to insert detail: " . $stmtDetail->error . " for item: " . json_encode($item));
        }
    }

    // Commit transaction
    $conn->commit();

    echo json_encode([
        "success" => true,
        "message" => "Invoice updated successfully",
        "invoice_id" => $invoiceid
    ]);
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();

    echo json_encode([
        "success" => false,
        "message" => "Failed to update invoice",
        "error" => $e->getMessage()
    ]);
}

$conn->close();
