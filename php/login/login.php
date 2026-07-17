<?php
include 'cors.php';
include 'conn.php';
header("Access-Control-Allow-Origin: *");
if ($conn->connect_error) {
 die("Connection failed: " . $conn->connect_error);
} 

 $json = file_get_contents('php://input');
 
 $obj = json_decode($json,true);
 
 $platform = $obj['platform'];
 $username = $obj['username'];
 $password = $obj['password'];
 $email = $obj['email'];
 $unique_id = $obj['unique_id'];
 $platform = $obj['platform'];


if($platform == 1){
$sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} else {
 echo "login not success";
}
}
else{
$sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
left join companymaster c on c.id = m.companyid where m.staffname = '$username' 
and  m.password = '$password' and c.email_id ='$email' and m.unique_id ='$unique_id'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} 

else {
	
$sql2 = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result2 = $conn->query($sql2);
 
if ($result2->num_rows >0) {
	
 $res=mysqli_query($conn,"select m.user_type,m.unique_id,m.id,m.companyid from staffmaster m 
 left join companymaster c on c.id = m.companyid WHERE m.staffname = '$username' 
 and  m.password = '$password' and c.email_id ='$email' limit 1");
 
 while($row=mysqli_fetch_array($res)) 	
 {
    $user_type =$row['user_type']; 
    $unique_identity =$row['unique_id']; 
    $user_id =$row['id']; 
    $company_id =$row['companyid']; 
 }

if($user_type != 'ADMIN'){	
 if (($unique_identity == '') || ($unique_identity == 'NULL')) {
	 
	 
$sqll = "SELECT * FROM staffmaster WHERE unique_id = '$unique_id'";
 
$resultl = $conn->query($sqll);
 
if ($resultl->num_rows >0) {
	
 echo "This is not your device.Please login in your device.";
  
}

else{	

 $Sql_Query = "UPDATE staffmaster SET unique_id = '$unique_id' WHERE id= '$user_id' and companyid = '$company_id'";
  
 if(mysqli_query($conn,$Sql_Query)){
	 
 $res=mysqli_query($conn,"select m.unique_id from staffmaster m 
 left join companymaster c on c.id = m.companyid 
 WHERE m.staffname = '$username' 
 and  m.password = '$password' and c.email_id ='$email' limit 1");
 
 while($row=mysqli_fetch_array($res)) 	
 {
    $unique_identity =$row['unique_id']; 
 }	 
	 
	
 $sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
 left join companymaster c on c.id = m.companyid 
 where m.staffname = '$username' and  m.password = '$password' 
 and c.email_id ='$email' and m.unique_id ='$unique_identity'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

 } 
else{
	
 echo "This is not your device.Please login in your device.";

 }	
 }
 else{
	
 echo "This is not your device.Please login in your device.";
	
 }
 }
 }
 else{
	
 echo "This is not your device.Please login in your device.";
	
}}

 else {
	 
	 $sql = "select m.staffname,m.PASSWORD,c.email_id from staffmaster m 
        left join companymaster c on c.id = m.companyid  
		where staffname = '$username' and  password = '$password' and email_id ='$email'";
 
$result = $conn->query($sql);
 
if ($result->num_rows >0) {
 
 echo "login success";

} else {
 echo "login not success";
}
	 
	 
 // echo "fsdffdsf";
}

 } 
 else {
 echo "login not success";
}
}
}

$conn->close();

?>



<!-- <?php
  header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: POST, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Accept, Cache-Control, X-Requested-With");
    header("Access-Control-Allow-Credentials: true");
    header('Access-Control-Max-Age: 86400');
    
    // Handle preflight requests
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit(0);
    }


// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method Not Allowed']);
    exit();
}

include 'conn.php';
include 'cors.php';

// Set response header
header('Content-Type: application/json; charset=utf-8');

// Get and validate JSON input
$json = file_get_contents('php://input');
// if (empty($json)) {
//     http_response_code(400);
//     echo json_encode(['status' => 'error', 'message' => 'Empty request body']);
//     exit();
// }

$data = json_decode($json, true);
// if (json_last_error() !== JSON_ERROR_NONE) {
//     http_response_code(400);
//     echo json_encode(['status' => 'error', 'message' => 'Invalid JSON format']);
//     exit();
// }

// Validate required fields
$requiredFields = ['username', 'password', 'email'];
foreach ($requiredFields as $field) {
    if (!isset($data[$field]) || trim($data[$field]) === '') {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => "Missing required field: $field"]);
        exit();
    }
}

// Sanitize inputs
if(!empty($data)){
    $username = trim($data['username']);
$password = trim($data['password']);
$email = trim($data['email']);
$platform = intval($data['platform']);
$unique_id = trim($data['unique_id']);}
else{
    
    $username = trim($_POST['username']);
$password = trim($_POST['password']);
$email = trim($_POST['email']);
$platform = intval($_POST['platform']);
$unique_id = trim($_POST['unique_id']);}


// Prevent SQL injection with prepared statements
try {
    // Determine query based on platform
    if ($platform === 1) {
        // Platform 1 query
        $sql = "SELECT m.salespersonname, m.PASSWORD, c.email_id 
                FROM salespersonmaster m 
                LEFT JOIN companymaster c ON c.id = m.companyid  
                WHERE m.salespersonname = ? AND m.password = ? AND c.email_id = ?";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Database prepare failed");
        }
        
        $stmt->bind_param("sss", $username, $password, $email);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            echo json_encode(['status' => 'success', 'message' => 'login success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Invalid credentials']);
        }
        $stmt->close();
    } else {
        // Platform 2 - More complex logic
        $response = handlePlatform2Login($conn, $username, $password, $email, $unique_id);
        echo json_encode($response);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Server error: ' . $e->getMessage()]);
} finally {
    $conn->close();
}

function handlePlatform2Login($conn, $username, $password, $email, $unique_id) {
    // First attempt: check with unique_id
    $sql = "SELECT m.salespersonname, m.PASSWORD, c.email_id 
            FROM salespersonmaster m 
            LEFT JOIN companymaster c ON c.id = m.companyid 
            WHERE m.salespersonname = ? AND m.password = ? AND c.email_id = ? 
            AND m.unique_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssss", $username, $password, $email, $unique_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $stmt->close();
    
    if ($result->num_rows > 0) {
        return ['status' => 'success', 'message' => 'login success'];
    }
    
    // Second attempt: check without unique_id
    $sql2 = "SELECT m.salespersonname, m.PASSWORD, c.email_id, m.user_type, 
                     m.unique_id, m.id, m.companyid 
              FROM salespersonmaster m 
              LEFT JOIN companymaster c ON c.id = m.companyid  
              WHERE m.salespersonname = ? AND m.password = ? AND c.email_id = ?";
    
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("sss", $username, $password, $email);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    if ($result2->num_rows === 0) {
        return ['status' => 'error', 'message' => 'Invalid credentials'];
    }
    
    // Get user data
    $user = $result2->fetch_assoc();
    $user_type = $user['user_type'];
    $unique_identity = $user['unique_id'];
    $user_id = $user['id'];
    $company_id = $user['companyid'];
    $stmt2->close();
    
    // ADMIN users bypass device check
    if ($user_type === 'ADMIN') {
        return ['status' => 'success', 'message' => 'login success'];
    }
    
    // Check if unique_id is already set
    if (empty($unique_identity) || $unique_identity === 'NULL') {
        // Check if unique_id is already used by another user
        $checkSql = "SELECT id FROM salespersonmaster WHERE unique_id = ? AND id != ?";
        $checkStmt = $conn->prepare($checkSql);
        $checkStmt->bind_param("si", $unique_id, $user_id);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        $checkStmt->close();
        
        if ($checkResult->num_rows > 0) {
            return ['status' => 'error', 'message' => 'This device is already registered to another user'];
        }
        
        // Update unique_id for this user
        $updateSql = "UPDATE salespersonmaster SET unique_id = ? WHERE id = ? AND companyid = ?";
        $updateStmt = $conn->prepare($updateSql);
        $updateStmt->bind_param("sii", $unique_id, $user_id, $company_id);
        $updateSuccess = $updateStmt->execute();
        $updateStmt->close();
        
        if (!$updateSuccess) {
            return ['status' => 'error', 'message' => 'Failed to register device'];
        }
        
        // Final verification
        $verifySql = "SELECT m.salespersonname, m.PASSWORD, c.email_id 
                      FROM salespersonmaster m 
                      LEFT JOIN companymaster c ON c.id = m.companyid 
                      WHERE m.salespersonname = ? AND m.password = ? 
                      AND c.email_id = ? AND m.unique_id = ?";
        
        $verifyStmt = $conn->prepare($verifySql);
        $verifyStmt->bind_param("ssss", $username, $password, $email, $unique_id);
        $verifyStmt->execute();
        $verifyResult = $verifyStmt->get_result();
        $verifyStmt->close();
        
        if ($verifyResult->num_rows > 0) {
            return ['status' => 'success', 'message' => 'login success'];
        } else {
            return ['status' => 'error', 'message' => 'Device registration failed'];
        }
    } else {
        return ['status' => 'error', 'message' => 'This is not your device. Please login on your device.'];
    }
}
?> -->