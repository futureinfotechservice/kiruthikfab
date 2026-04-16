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
    $source_id = mysqli_real_escape_string($conn, $obj['source_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $obj['companyid'] ?? '');
    $source_date = mysqli_real_escape_string($conn, $obj['source_date'] ?? '');
    $branch = mysqli_real_escape_string($conn, $obj['branch'] ?? '');
    $name = mysqli_real_escape_string($conn, $obj['name'] ?? '');
    $company_name = mysqli_real_escape_string($conn, $obj['company_name'] ?? '');
    $mobile_no = mysqli_real_escape_string($conn, $obj['mobile_no'] ?? '');
    $contact_no = mysqli_real_escape_string($conn, $obj['contact_no'] ?? '');
    $whatsapp_no = mysqli_real_escape_string($conn, $obj['whatsapp_no'] ?? '');
    $area = mysqli_real_escape_string($conn, $obj['area'] ?? '');
    $area_id = mysqli_real_escape_string($conn, $obj['area_id'] ?? '');
    $address = mysqli_real_escape_string($conn, $obj['address'] ?? '');
    $occupation = mysqli_real_escape_string($conn, $obj['occupation'] ?? '');
    $occupation_id = mysqli_real_escape_string($conn, $obj['occupation_id'] ?? '');
    $refer_by = mysqli_real_escape_string($conn, $obj['refer_by'] ?? '');
    $refer_by_id = mysqli_real_escape_string($conn, $obj['refer_by_id'] ?? '');
    $agent = mysqli_real_escape_string($conn, $obj['agent'] ?? '');
    $agent_id = mysqli_real_escape_string($conn, $obj['agent_id'] ?? '');
    $sourcing_mode = mysqli_real_escape_string($conn, $obj['sourcing_mode'] ?? '');
    $sourcing_mode_id = mysqli_real_escape_string($conn, $obj['sourcing_mode_id'] ?? '');
    $entry_person = mysqli_real_escape_string($conn, $obj['entry_person'] ?? '');
    $entry_person_id = mysqli_real_escape_string($conn, $obj['entry_person_id'] ?? '');
    $background_network = mysqli_real_escape_string($conn, $obj['background_network'] ?? '');
    $customer_interest = mysqli_real_escape_string($conn, $obj['customer_interest'] ?? '');
    $notes = mysqli_real_escape_string($conn, $obj['notes'] ?? '');
    $sales_person = mysqli_real_escape_string($conn, $obj['sales_person'] ?? '');
    $sales_person_id = mysqli_real_escape_string($conn, $obj['sales_person_id'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $obj['addedby'] ?? '');
} else {
    $source_id = mysqli_real_escape_string($conn, $_POST['source_id'] ?? '');
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $source_date = mysqli_real_escape_string($conn, $_POST['source_date'] ?? '');
    $branch = mysqli_real_escape_string($conn, $_POST['branch'] ?? '');
    $name = mysqli_real_escape_string($conn, $_POST['name'] ?? '');
    $company_name = mysqli_real_escape_string($conn, $_POST['company_name'] ?? '');
    $mobile_no = mysqli_real_escape_string($conn, $_POST['mobile_no'] ?? '');
    $contact_no = mysqli_real_escape_string($conn, $_POST['contact_no'] ?? '');
    $whatsapp_no = mysqli_real_escape_string($conn, $_POST['whatsapp_no'] ?? '');
    $area = mysqli_real_escape_string($conn, $_POST['area'] ?? '');
    $area_id = mysqli_real_escape_string($conn, $_POST['area_id'] ?? '');
    $address = mysqli_real_escape_string($conn, $_POST['address'] ?? '');
    $occupation = mysqli_real_escape_string($conn, $_POST['occupation'] ?? '');
    $occupation_id = mysqli_real_escape_string($conn, $_POST['occupation_id'] ?? '');
    $refer_by = mysqli_real_escape_string($conn, $_POST['refer_by'] ?? '');
    $refer_by_id = mysqli_real_escape_string($conn, $_POST['refer_by_id'] ?? '');
    $agent = mysqli_real_escape_string($conn, $_POST['agent'] ?? '');
    $agent_id = mysqli_real_escape_string($conn, $_POST['agent_id'] ?? '');
    $sourcing_mode = mysqli_real_escape_string($conn, $_POST['sourcing_mode'] ?? '');
    $sourcing_mode_id = mysqli_real_escape_string($conn, $_POST['sourcing_mode_id'] ?? '');
    $entry_person = mysqli_real_escape_string($conn, $_POST['entry_person'] ?? '');
    $entry_person_id = mysqli_real_escape_string($conn, $_POST['entry_person_id'] ?? '');
    $background_network = mysqli_real_escape_string($conn, $_POST['background_network'] ?? '');
    $customer_interest = mysqli_real_escape_string($conn, $_POST['customer_interest'] ?? '');
    $notes = mysqli_real_escape_string($conn, $_POST['notes'] ?? '');
    $sales_person = mysqli_real_escape_string($conn, $_POST['sales_person'] ?? '');
    $sales_person_id = mysqli_real_escape_string($conn, $_POST['sales_person_id'] ?? '');
    $addedby = mysqli_real_escape_string($conn, $_POST['addedby'] ?? '');
}

if (empty($source_id)) {
    echo json_encode(["status" => "error", "message" => "Source ID is required"]);
    mysqli_close($conn);
    exit();
}

// Convert date format
if (!empty($source_date)) {
    $date_parts = explode('/', $source_date);
    if (count($date_parts) == 3) {
        $source_date = $date_parts[2] . '-' . $date_parts[1] . '-' . $date_parts[0];
    }
}

$sql = "UPDATE sourcemaster SET 
    source_date = '$source_date',
    branch = '$branch',
    name = '$name',
    company_name = '$company_name',
    mobile_no = '$mobile_no',
    contact_no = '$contact_no',
    whatsapp_no = '$whatsapp_no',
    area = '$area',
    area_id = '$area_id',
    address = '$address',
    occupation = '$occupation',
    occupation_id = '$occupation_id',
    refer_by = '$refer_by',
    refer_by_id = '$refer_by_id',
    agent = '$agent',
    agent_id = '$agent_id',
    sourcing_mode = '$sourcing_mode',
    sourcing_mode_id = '$sourcing_mode_id',
    entry_person = '$entry_person',
    entry_person_id = '$entry_person_id',
    background_network = '$background_network',
    customer_interest = '$customer_interest',
    notes = '$notes',
    sales_person = '$sales_person',
    sales_person_id = '$sales_person_id',
    addedby = '$addedby'
WHERE id = '$source_id' AND companyid = '$companyid'";

if (mysqli_query($conn, $sql)) {
    echo json_encode(["status" => "success", "message" => "Source updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>