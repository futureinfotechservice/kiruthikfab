<?php
include 'conn.php';
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

$sql = "SELECT * FROM sourcemaster WHERE companyid = '$companyid' AND activestatus = '1' ORDER BY id DESC";
$result = mysqli_query($conn, $sql);

$sources = [];
if (mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        // Format date for display
        if (!empty($row['source_date'])) {
            $date = new DateTime($row['source_date']);
            $row['source_date_display'] = $date->format('d/m/Y');
        }
        $sources[] = $row;
    }
}

echo json_encode($sources);
mysqli_close($conn);
?>