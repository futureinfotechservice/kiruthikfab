<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$kyc_id = isset($_POST['kyc_id']) ? mysqli_real_escape_string($conn, $_POST['kyc_id']) : '';
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

if (empty($kyc_id) || empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "KYC ID and Company ID are required"]);
    mysqli_close($conn);
    exit();
}

mysqli_begin_transaction($conn);

try {
    mysqli_query($conn, "DELETE FROM kyc_family_members WHERE kyc_id = '$kyc_id'");
    mysqli_query($conn, "DELETE FROM kyc_products WHERE kyc_id = '$kyc_id'");
    mysqli_query($conn, "DELETE FROM kyc_product_sections WHERE kyc_id = '$kyc_id'");
    
    $sql = "UPDATE kyc_master SET activestatus = '0' WHERE id = '$kyc_id' AND companyid = '$companyid'";
    
    if (mysqli_query($conn, $sql)) {
        mysqli_commit($conn);
        echo json_encode(["status" => "success", "message" => "KYC deleted successfully"]);
    } else {
        throw new Exception("Failed to delete KYC");
    }
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

mysqli_close($conn);
?>