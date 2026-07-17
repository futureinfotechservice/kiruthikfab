<?php

$servername = "localhost";
$database = "u258460312_kiruthikfab";
$username = "u258460312_fab_user";
$password = "Sbva/tech1";
 
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
 try {
    $conn = mysqli_connect($servername, $username, $password, $database);
    
    if (!$conn) {
        throw new Exception("Connection failed: " . mysqli_connect_error());
    }
    
    // Set charset
    mysqli_set_charset($conn, "utf8mb4");
    
} catch (Exception $e) {
    // Log error but don't expose to client
    error_log("Database connection error: " . $e->getMessage());
    
    // Return JSON error
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit();
}
// $conn = mysqli_connect($servername, $username, $password, $database);
 
// include 'cors.php';
// $servername = "futureinfotechservices.in";
 
// if (!$conn) {
 
    // die("Connection failed: " . mysqli_connect_error());
 
// }
// echo "Connected successfully";
// mysqli_close($conn);
?>
