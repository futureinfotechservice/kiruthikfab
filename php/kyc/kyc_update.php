<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj)) {
    $kyc_id = mysqli_real_escape_string($conn, $obj['kyc_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
    $customer_id = mysqli_real_escape_string($conn, $obj['customer_id'] ?? '');
    $customer_name = mysqli_real_escape_string($conn, $obj['customer_name'] ?? '');
    $total_amount = mysqli_real_escape_string($conn, $obj['total_amount'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $obj['addedby'] ?? '');
    $family_members = $obj['family_members'] ?? [];
    $product_sections = $obj['product_sections'] ?? [];
} else {
    $kyc_id = mysqli_real_escape_string($conn, $_POST['kyc_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $customer_id = mysqli_real_escape_string($conn, $_POST['customer_id'] ?? '');
    $customer_name = mysqli_real_escape_string($conn, $_POST['customer_name'] ?? '');
    $total_amount = mysqli_real_escape_string($conn, $_POST['total_amount'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');
    $family_members = json_decode($_POST['family_members'] ?? '[]', true);
    $product_sections = json_decode($_POST['product_sections'] ?? '[]', true);
}

if (empty($kyc_id)) {
    echo json_encode(["status" => "error", "message" => "KYC ID is required"]);
    mysqli_close($conn);
    exit();
}

mysqli_begin_transaction($conn);

try {
    // Update KYC Master
    $sql = "UPDATE kyc_master SET customer_id = '$customer_id', customer_name = '$customer_name', total_amount = '$total_amount', addedby = '$addedby' 
            WHERE id = '$kyc_id' AND companyid = '$companyid'";
    
    if (!mysqli_query($conn, $sql)) {
        throw new Exception("Failed to update KYC: " . mysqli_error($conn));
    }
    
    // Delete existing family members and products
    mysqli_query($conn, "DELETE FROM kyc_family_members WHERE kyc_id = '$kyc_id'");
    mysqli_query($conn, "DELETE FROM kyc_products WHERE kyc_id = '$kyc_id'");
    mysqli_query($conn, "DELETE FROM kyc_product_sections WHERE kyc_id = '$kyc_id'");
    
    // Insert Family Members
    foreach ($family_members as $index => $member) {
        $member_name = mysqli_real_escape_string($conn, $member['name'] ?? '');
        $gender = mysqli_real_escape_string($conn, $member['gender'] ?? '');
        $age = mysqli_real_escape_string($conn, $member['age'] ?? '0');
        $relation = mysqli_real_escape_string($conn, $member['relation'] ?? '');
        $occupation = mysqli_real_escape_string($conn, $member['occupation'] ?? '');
        $occupation_id = mysqli_real_escape_string($conn, $member['occupation_id'] ?? '');
        $sort_order = $index + 1;
        
        $sql = "INSERT INTO kyc_family_members (kyc_id, companyid, member_name, gender, age, relation, occupation, occupation_id, sort_order) 
                VALUES ('$kyc_id', '$companyid', '$member_name', '$gender', '$age', '$relation', '$occupation', '$occupation_id', '$sort_order')";
        
        if (!mysqli_query($conn, $sql)) {
            throw new Exception("Failed to insert family member: " . mysqli_error($conn));
        }
    }
    
    // Insert Product Sections and Products
    foreach ($product_sections as $section_index => $section) {
        $section_name = mysqli_real_escape_string($conn, $section['section_name'] ?? '');
        $section_order = $section_index + 1;
        
        $sql = "INSERT INTO kyc_product_sections (kyc_id, companyid, section_name, section_order) 
                VALUES ('$kyc_id', '$companyid', '$section_name', '$section_order')";
        
        if (!mysqli_query($conn, $sql)) {
            throw new Exception("Failed to insert product section: " . mysqli_error($conn));
        }
        
        $section_id = mysqli_insert_id($conn);
        
        foreach ($section['products'] as $product_index => $product) {
            $product_id = mysqli_real_escape_string($conn, $product['product_id'] ?? '');
            $product_name = mysqli_real_escape_string($conn, $product['product_name'] ?? '');
            $size = mysqli_real_escape_string($conn, $product['size'] ?? '');
            $quantity = mysqli_real_escape_string($conn, $product['quantity'] ?? '0');
            $price = mysqli_real_escape_string($conn, $product['price'] ?? '0');
            $total = mysqli_real_escape_string($conn, $product['total'] ?? '0');
            $sort_order = $product_index + 1;
            
            $sql = "INSERT INTO kyc_products (kyc_id, companyid, product_id, product_name, size, quantity, price, total_amount, sort_order) 
                    VALUES ('$kyc_id', '$companyid', '$product_id', '$product_name', '$size', '$quantity', '$price', '$total', '$sort_order')";
            
            if (!mysqli_query($conn, $sql)) {
                throw new Exception("Failed to insert product: " . mysqli_error($conn));
            }
        }
    }
    
    mysqli_commit($conn);
    echo json_encode(["status" => "success", "message" => "KYC updated successfully"]);
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

mysqli_close($conn);
?>