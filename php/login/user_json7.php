<?php
include 'conn.php';
header("Access-Control-Allow-Origin: *");
if ($conn->connect_error) {

    die("Connection failed: " . $conn->connect_error);
}

$json = file_get_contents('php://input');

// Decoding the received JSON and store into $obj variable.
$obj = json_decode($json, true);

// Getting User email from JSON $obj array and store into $email.
$username = $obj['username'];
$password = $obj['password'];
$email = $obj['email'];
// $userid = '1';

$sql = "SELECT 
    sm.id,
    sm.salespersonname,
    sm.type,
    sm.password,
    cm.email_id,
    sm.companyid,
    sm.activestatus,
    cm.activestatus as companystatus,

   
    cm.companyname,
    cm.logourl 
FROM salespersonmaster as sm 
LEFT JOIN companymaster as cm on sm.companyid = cm.id 

WHERE cm.email_id = '$email' 
    AND sm.salespersonname = '$username' 
    AND sm.password = '$password'
GROUP BY 
    sm.id, sm.salespersonname, sm.type, sm.password, cm.email_id, sm.companyid, 
    sm.activestatus, cm.activestatus,  cm.companyname, cm.logourl";

$result = $conn->query($sql);

if ($result->num_rows > 0) {


    $spacecrafts = array();
    while ($row = $result->fetch_array()) {
        array_push($spacecrafts, array(
            "id" => $row['id'],
            "username" => $row['salespersonname'],
            "password" => $row['password'],
            "email_id" => $row['email_id'],
            "user_type" => $row['type'],
            "companyid" => $row['companyid'],
            "activestatus" => $row['activestatus'],
            "companystatus" => $row['companystatus'],

            "companyname" => $row['companyname'],
            "logourl" => $row['logourl'],

        ));
    }
    print(json_encode(array_reverse($spacecrafts)));
} else {
    echo "No Data Found.";
}
// echo $json;
$conn->close();
