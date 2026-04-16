<?php
include 'conn.php';
include 'cors.php';
 
$head_id = $_POST['head_id'];
// $companyid = $_POST['companyid'];

if(empty($head_id) //|| empty($companyid)
    ){
    echo json_encode([
        "status"=>"error",
        "message"=>"Missing required fields"
    ]);
    exit();
}

$sql = "SELECT id, head_id, checklist, date, isChecked 
        FROM delivery_details 
        WHERE head_id = '$head_id' 
        ORDER BY id ASC";

$result = mysqli_query($conn, $sql);

$details = [];
while($row = mysqli_fetch_assoc($result)){
    $details[] = $row;
}

echo json_encode([
    "status"=>"success",
    "details"=>$details
]);
?>