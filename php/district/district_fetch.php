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
    *
    FROM district_master 
    WHERE companyid = '$companyid'  
    ORDER BY district_name ASC";

$result = $conn->query($sql);
$relations = array();

if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $relations[] = $row;
    }
    echo json_encode($relations);
} else {
    echo json_encode([]);
}

$conn->close();
?>