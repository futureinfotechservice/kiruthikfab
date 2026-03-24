<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Handle both JSON and POST data
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj)) {
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
    $customername = mysqli_real_escape_string($conn, $obj['customername'] ?? '');
    $gst_no = mysqli_real_escape_string($conn, $obj['gst_no'] ?? '');
    $address = mysqli_real_escape_string($conn, $obj['address'] ?? '');
    $area = mysqli_real_escape_string($conn, $obj['area'] ?? '');
    $areaid = mysqli_real_escape_string($conn, $obj['areaid'] ?? '');
    $mobile1 = mysqli_real_escape_string($conn, $obj['mobile1'] ?? '');
    $mobile2 = mysqli_real_escape_string($conn, $obj['mobile2'] ?? '');
    $whatsapp = mysqli_real_escape_string($conn, $obj['whatsapp'] ?? '');
    $refer = mysqli_real_escape_string($conn, $obj['refer'] ?? '');
    $incharge = mysqli_real_escape_string($conn, $obj['incharge'] ?? '');
    $agent = mysqli_real_escape_string($conn, $obj['agent'] ?? '');
    $salesperson = mysqli_real_escape_string($conn, $obj['salesperson'] ?? '');
    $occupation = mysqli_real_escape_string($conn, $obj['occupation'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $obj['addedby'] ?? '');
    $activestatus = mysqli_real_escape_string($conn, $obj['activestatus'] ?? '1');
    
    $aadhar_base64 = $obj['aadhar_base64'] ?? '';
    $photo_base64 = $obj['photo_base64'] ?? '';
    $aadhar_filename = $obj['aadhar_filename'] ?? '';
    $photo_filename = $obj['photo_filename'] ?? '';
} else {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $customername = mysqli_real_escape_string($conn, $_POST['customername'] ?? '');
    $gst_no = mysqli_real_escape_string($conn, $_POST['gst_no'] ?? '');
    $address = mysqli_real_escape_string($conn, $_POST['address'] ?? '');
    $area = mysqli_real_escape_string($conn, $_POST['area'] ?? '');
    $areaid = mysqli_real_escape_string($conn, $_POST['areaid'] ?? '');
    $mobile1 = mysqli_real_escape_string($conn, $_POST['mobile1'] ?? '');
    $mobile2 = mysqli_real_escape_string($conn, $_POST['mobile2'] ?? '');
    $whatsapp = mysqli_real_escape_string($conn, $_POST['whatsapp'] ?? '');
    $refer = mysqli_real_escape_string($conn, $_POST['refer'] ?? '');
    $incharge = mysqli_real_escape_string($conn, $_POST['incharge'] ?? '');
    $agent = mysqli_real_escape_string($conn, $_POST['agent'] ?? '');
    $salesperson = mysqli_real_escape_string($conn, $_POST['salesperson'] ?? '');
    $occupation = mysqli_real_escape_string($conn, $_POST['occupation'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');
    $activestatus = mysqli_real_escape_string($conn, $_POST['activestatus'] ?? '1');
    
    $aadhar_base64 = $_POST['aadhar_base64'] ?? '';
    $photo_base64 = $_POST['photo_base64'] ?? '';
    $aadhar_filename = $_POST['aadhar_filename'] ?? '';
    $photo_filename = $_POST['photo_filename'] ?? '';
}

// Validate required fields
$required_fields = ['customername', 'address', 'area', 'mobile1']; // 'refer', 'incharge', 'agent', 'salesperson'
foreach ($required_fields as $field) {
    if (empty($$field)) {
        echo json_encode(["status" => "error", "message" => ucfirst($field) . " is required"]);
        mysqli_close($conn);
        exit();
    }
}

// Check if mobile number already exists
$check_query = "SELECT id FROM customermaster WHERE mobile1 = '$mobile1' AND companyid = '$companyid'";
$result = mysqli_query($conn, $check_query);
if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Mobile number already exists"]);
    mysqli_close($conn);
    exit();
}

// Handle file uploads
$aadharurl = '';
$photourl = '';

// Create upload directory if not exists
$upload_dir = 'uploads/customers/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

// Process Aadhar file
if (!empty($aadhar_base64)) {
    $aadhar_data = explode(',', $aadhar_base64);
    $aadhar_file_data = base64_decode($aadhar_data[1] ?? $aadhar_data[0]);
    $aadhar_filename = !empty($aadhar_filename) ? $aadhar_filename : 'aadhar_' . uniqid() . '.jpg';
    $aadhar_path = $upload_dir . $aadhar_filename;
    file_put_contents($aadhar_path, $aadhar_file_data);
    $aadharurl = 'https://kiruthikfabapi.futureinfotechservices.in/' . $aadhar_path;
}

// Process Photo file
if (!empty($photo_base64)) {
    $photo_data = explode(',', $photo_base64);
    $photo_file_data = base64_decode($photo_data[1] ?? $photo_data[0]);
    $photo_filename = !empty($photo_filename) ? $photo_filename : 'photo_' . uniqid() . '.jpg';
    $photo_path = $upload_dir . $photo_filename;
    file_put_contents($photo_path, $photo_file_data);
    $photourl = 'https://kiruthikfabapi.futureinfotechservices.in/' . $photo_path;
}

// Insert query
$sql = "INSERT INTO customermaster (
    companyid, customername, gst_no, address, area, areaid, 
    mobile1, mobile2, whatsapp, refer, incharge, agent, salesperson, 
    occupation, aadharurl, photourl, addedby, activestatus
) VALUES (
    '$companyid', '$customername', '$gst_no', '$address', '$area', '$areaid',
    '$mobile1', '$mobile2', '$whatsapp', '$refer', '$incharge', '$agent', '$salesperson',
    '$occupation', '$aadharurl', '$photourl', '$addedby', '$activestatus'
)";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Customer created successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>