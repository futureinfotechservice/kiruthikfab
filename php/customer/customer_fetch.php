<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

// Get POST data
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';

// Also check JSON input
$json = file_get_contents('php://input');
if (!empty($json)) {
    $obj = json_decode($json, true);
    if (isset($obj['companyid'])) {
        $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
    }
}

if (empty($companyid)) {
    echo json_encode(["error" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

$sql = "SELECT 
    id, 
    companyid, 
    customername, 
    IFNULL(gst_no, '') as gst_no, 
    address, 
    area, 
    IFNULL(areaid, '') as areaid, 
    mobile1, 
    IFNULL(mobile2, '') as mobile2, 
    IFNULL(whatsapp, '') as whatsapp,
    refer, 
    incharge, 
    agent, 
    salesperson, 
    IFNULL(occupation, '') as occupation,
    IFNULL(aadharurl, '') as aadharurl, 
    IFNULL(photourl, '') as photourl,
    addedby, 
    activestatus 
    FROM customermaster 
    WHERE companyid = '$companyid' AND activestatus = '1' 
    ORDER BY id DESC";

$result = $conn->query($sql);
$customers = array();

if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $customers[] = $row;
    }
    echo json_encode($customers);
} else {
    echo json_encode([]); // Return empty array instead of "No Data Found"
}

$conn->close();
?>