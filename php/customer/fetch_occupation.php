<?php
include 'conn.php';
include 'cors.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]));
}

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

$sql = "SELECT id, occupationname FROM occupationmaster WHERE companyid = '$companyid' AND activestatus = '1' ORDER BY occupationname";
$result = mysqli_query($conn, $sql);

$occupations = [];
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        $occupations[] = [
            'id' => $row['id'],
            'name' => $row['occupationname']
        ];
    }
}

echo json_encode(["status" => "success", "data" => $occupations]);
mysqli_close($conn);
?>