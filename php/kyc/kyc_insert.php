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
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
    $customer_id = mysqli_real_escape_string($conn, $obj['customer_id'] ?? '');
    $customer_name = mysqli_real_escape_string($conn, $obj['customer_name'] ?? '');
    $total_amount = mysqli_real_escape_string($conn, $obj['total_amount'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $obj['addedby'] ?? '');
    $family_members = $obj['family_members'] ?? [];
} else {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $customer_id = mysqli_real_escape_string($conn, $_POST['customer_id'] ?? '');
    $customer_name = mysqli_real_escape_string($conn, $_POST['customer_name'] ?? '');
    $total_amount = mysqli_real_escape_string($conn, $_POST['total_amount'] ?? '0');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');
    $family_members = json_decode($_POST['family_members'] ?? '[]', true);
}

if (empty($customer_id)) {
    echo json_encode(["status" => "error", "message" => "Customer is required"]);
    mysqli_close($conn);
    exit();
}

mysqli_begin_transaction($conn);

try {
    // Insert KYC Master
    $sql = "INSERT INTO kyc_master (companyid, customer_id, customer_name, total_amount, addedby) 
            VALUES ('$companyid', '$customer_id', '$customer_name', '$total_amount', '$addedby')";
    
    if (!mysqli_query($conn, $sql)) {
        throw new Exception("Failed to insert KYC: " . mysqli_error($conn));
    }
    
    $kyc_id = mysqli_insert_id($conn);
    
    // Insert Family Members and their Products
    foreach ($family_members as $index => $member) {
        $member_name = mysqli_real_escape_string($conn, $member['name'] ?? '');
        $gender = mysqli_real_escape_string($conn, $member['gender'] ?? '');
        $age = mysqli_real_escape_string($conn, $member['age'] ?? '0');
        $relation = mysqli_real_escape_string($conn, $member['relation'] ?? '');
        $occupation = mysqli_real_escape_string($conn, $member['occupation'] ?? '');
        $occupation_id = mysqli_real_escape_string($conn, $member['occupation_id'] ?? '');
        $member_total = mysqli_real_escape_string($conn, $member['member_total'] ?? '0');
        $sort_order = $index + 1;
        
        $sql = "INSERT INTO kyc_family_members (kyc_id, companyid, member_name, gender, age, relation, occupation, occupation_id, member_total, sort_order) 
                VALUES ('$kyc_id', '$companyid', '$member_name', '$gender', '$age', '$relation', '$occupation', '$occupation_id', '$member_total', '$sort_order')";
        
        if (!mysqli_query($conn, $sql)) {
            throw new Exception("Failed to insert family member: " . mysqli_error($conn));
        }
        
        $family_member_id = mysqli_insert_id($conn);
        
        // Insert Products for this family member
        $products = $member['products'] ?? [];
        foreach ($products as $product_index => $product) {
            $product_id = mysqli_real_escape_string($conn, $product['product_id'] ?? '');
            $product_name = mysqli_real_escape_string($conn, $product['product_name'] ?? '');
            $size = mysqli_real_escape_string($conn, $product['size'] ?? '');
            $quantity = mysqli_real_escape_string($conn, $product['quantity'] ?? '0');
            $price = mysqli_real_escape_string($conn, $product['price'] ?? '0');
            $total = mysqli_real_escape_string($conn, $product['total'] ?? '0');
            $product_sort_order = $product_index + 1;
            
            $sql = "INSERT INTO kyc_products (kyc_id, family_member_id, companyid, product_id, product_name, size, quantity, price, total_amount, sort_order) 
                    VALUES ('$kyc_id', '$family_member_id', '$companyid', '$product_id', '$product_name', '$size', '$quantity', '$price', '$total', '$product_sort_order')";
            
            if (!mysqli_query($conn, $sql)) {
                throw new Exception("Failed to insert product: " . mysqli_error($conn));
            }
        }
    }
    
    mysqli_commit($conn);
    echo json_encode(["status" => "success", "message" => "KYC saved successfully", "kyc_id" => $kyc_id]);
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}

mysqli_close($conn);
?>