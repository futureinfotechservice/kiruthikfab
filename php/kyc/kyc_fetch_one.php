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

$sql = "SELECT * FROM kyc_master WHERE id = '$kyc_id' AND companyid = '$companyid'";
$result = mysqli_query($conn, $sql);
$kyc = mysqli_fetch_assoc($result);

if ($kyc) {
    // Fetch family members
    $member_sql = "SELECT * FROM kyc_family_members WHERE kyc_id = '$kyc_id' ORDER BY sort_order";
    $member_result = mysqli_query($conn, $member_sql);
    $family_members = [];
    while ($member = mysqli_fetch_assoc($member_result)) {
        $family_members[] = $member;
    }
    
    // Fetch product sections
    $section_sql = "SELECT * FROM kyc_product_sections WHERE kyc_id = '$kyc_id' ORDER BY section_order";
    $section_result = mysqli_query($conn, $section_sql);
    $product_sections = [];
    while ($section = mysqli_fetch_assoc($section_result)) {
        $section_id = $section['id'];
        $product_sql = "SELECT * FROM kyc_products WHERE kyc_id = '$kyc_id' AND companyid = '$companyid' ORDER BY sort_order";
        $product_result = mysqli_query($conn, $product_sql);
        $products = [];
        while ($product = mysqli_fetch_assoc($product_result)) {
            $products[] = $product;
        }
        $section['products'] = $products;
        $product_sections[] = $section;
    }
    
    $kyc['family_members'] = $family_members;
    $kyc['product_sections'] = $product_sections;
    echo json_encode(["status" => "success", "data" => $kyc]);
} else {
    echo json_encode(["status" => "error", "message" => "KYC not found"]);
}

mysqli_close($conn);
?>