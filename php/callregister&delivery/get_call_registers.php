<?php

include 'conn.php';
include 'cors.php';
 
$companyid = $_POST['companyid'];

$sql = "
SELECT
cr.id,
cr.entry_no,
DATE_FORMAT(cr.date,'%d/%m/%Y') date,
cr.`from`,
cr.`to`,
s.name source_name,
st.salespersonname call_by,
cr.feedback,
cr.notes
FROM call_register cr

LEFT JOIN sourcemaster s
ON s.id = cr.source_id

LEFT JOIN salespersonmaster st
ON st.id = cr.call_by_id

WHERE cr.companyid='$companyid'

ORDER BY cr.id DESC
";

$result=mysqli_query($conn,$sql);

$data=[];

while($row=mysqli_fetch_assoc($result)){
    $data[]=$row;
}

echo json_encode([
    "status"=>true,
    "data"=>$data
]);

?>