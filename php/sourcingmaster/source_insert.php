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
    $source_no = mysqli_real_escape_string($conn, $obj['source_no'] ?? '');
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
    $activestatus = mysqli_real_escape_string($conn, $obj['activestatus'] ?? '1');
} else {
    $companyid = mysqli_real_escape_string($conn, $_POST['companyid'] ?? '');
    $source_no = mysqli_real_escape_string($conn, $_POST['source_no'] ?? '');
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
    $activestatus = mysqli_real_escape_string($conn, $_POST['activestatus'] ?? '1');
}

// Validate required fields
$required_fields = ['name', 'mobile_no', 'branch', 'sourcing_mode_id'];
foreach ($required_fields as $field) {
    if (empty($$field)) {
        echo json_encode(["status" => "error", "message" => ucfirst(str_replace('_', ' ', $field)) . " is required"]);
        mysqli_close($conn);
        exit();
    }
}

// Check if mobile number already exists
$check_query = "SELECT id FROM sourcemaster WHERE mobile_no = '$mobile_no' AND companyid = '$companyid'";
$result = mysqli_query($conn, $check_query);
if (mysqli_num_rows($result) > 0) {
    echo json_encode(["status" => "error", "message" => "Mobile number already exists"]);
    mysqli_close($conn);
    exit();
}

// Get next source number if not provided
if (empty($source_no)) {
    $max_query = "SELECT MAX(CAST(SUBSTRING_INDEX(source_no, '-', -1) AS UNSIGNED)) as max_no FROM sourcemaster WHERE companyid = '$companyid'";
    $max_result = mysqli_query($conn, $max_query);
    $max_row = mysqli_fetch_assoc($max_result);
    $next_no = ($max_row['max_no'] ?? 0) + 1;
    $source_no = "SRC-" . str_pad($next_no, 6, '0', STR_PAD_LEFT);
}

// Convert date format from dd/mm/yyyy to yyyy-mm-dd
if (!empty($source_date)) {
    $date_parts = explode('/', $source_date);
    if (count($date_parts) == 3) {
        $source_date = $date_parts[2] . '-' . $date_parts[1] . '-' . $date_parts[0];
    }
}

$sql = "INSERT INTO sourcemaster (
    companyid, source_no, source_date, branch, name, company_name,
    mobile_no, contact_no, whatsapp_no, area, area_id, address,
    occupation, occupation_id, refer_by, refer_by_id, agent, agent_id,
    sourcing_mode, sourcing_mode_id, entry_person, entry_person_id,
    background_network, customer_interest, notes, sales_person, sales_person_id,
    addedby, activestatus
) VALUES (
    '$companyid', '$source_no', '$source_date', '$branch', '$name', '$company_name',
    '$mobile_no', '$contact_no', '$whatsapp_no', '$area', '$area_id', '$address',
    '$occupation', '$occupation_id', '$refer_by', '$refer_by_id', '$agent', '$agent_id',
    '$sourcing_mode', '$sourcing_mode_id', '$entry_person', '$entry_person_id',
    '$background_network', '$customer_interest', '$notes', '$sales_person', '$sales_person_id',
    '$addedby', '$activestatus'
)";

if (mysqli_query($conn, $sql)) {
    echo json_encode([
        "status" => "success", 
        "message" => "Source created successfully",
        "source_no" => $source_no
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>