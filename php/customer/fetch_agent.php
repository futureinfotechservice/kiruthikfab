<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

// Get companyid from POST request
$companyid = isset($_POST['companyid']) ? mysqli_real_escape_string($conn, $_POST['companyid']) : '';
$json = file_get_contents('php://input');
$obj = json_decode($json, true);

if (!empty($obj) && isset($obj['companyid'])) {
    $companyid = mysqli_real_escape_string($conn, $obj['companyid']);
}

if (empty($companyid)) {
    echo json_encode(["status" => "error", "message" => "Company ID is required"]);
    mysqli_close($conn);
    exit();
}

$sql = "SELECT id, agentname FROM agentmaster WHERE companyid = '$companyid' AND activestatus = '1' ORDER BY agentname";
$result = mysqli_query($conn, $sql);

$agents = [];
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $agents[] = [
            'id' => $row['id'],
            'name' => $row['agentname']
        ];
    }
}

echo json_encode(["status" => "success", "data" => $agents]);
mysqli_close($conn);
?>