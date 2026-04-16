<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

$sql = "SELECT * FROM kyc_master WHERE companyid = '$companyid' AND activestatus = '1' ORDER BY id DESC";
$result = mysqli_query($conn, $sql);

$kyc_list = [];
while ($row = mysqli_fetch_assoc($result)) {
    $kyc_id = $row['id'];
    
    // Fetch family members
    $member_sql = "SELECT * FROM kyc_family_members WHERE kyc_id = '$kyc_id' ORDER BY sort_order";
    $member_result = mysqli_query($conn, $member_sql);
    $family_members = [];
    while ($member = mysqli_fetch_assoc($member_result)) {
        $member_id = $member['id'];
        
        // Fetch products for this family member
        $product_sql = "SELECT * FROM kyc_products WHERE kyc_id = '$kyc_id' AND family_member_id = '$member_id' ORDER BY sort_order";
        $product_result = mysqli_query($conn, $product_sql);
        $products = [];
        while ($product = mysqli_fetch_assoc($product_result)) {
            $products[] = $product;
        }
        
        $member['products'] = $products;
        $family_members[] = $member;
    }
    
    $row['family_members'] = $family_members;
    $kyc_list[] = $row;
}

echo json_encode($kyc_list);
mysqli_close($conn);
?>