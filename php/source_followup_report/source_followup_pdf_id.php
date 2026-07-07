<?php

require_once('tcpdf/tcpdf.php');
include 'conn.php';
include 'cors.php';

$companyid = $_GET['companyid'] ?? '';
$id        = $_GET['id'] ?? '';

if (empty($companyid) || empty($id)) {
    die("Company ID and User ID are required.");
}

/* ==========================
   Company Name
========================== */

$companyName = '';

$cmp = mysqli_query($conn, "SELECT companyname FROM companymaster WHERE id='$companyid' LIMIT 1");

if ($cmp && mysqli_num_rows($cmp) > 0) {
    $companyName = mysqli_fetch_assoc($cmp)['companyname'];
}

/* ==========================
   PDF
========================== */

$pdf = new TCPDF('L', 'mm', 'A4', true, 'UTF-8', false);

$pdf->SetCreator('ERP');
$pdf->SetAuthor('ERP');
$pdf->SetTitle('Source Followup Report');

$pdf->SetMargins(5, 10, 5);
$pdf->SetAutoPageBreak(TRUE, 10);

$pdf->setPrintHeader(false);
$pdf->setPrintFooter(false);

$pdf->SetFont('dejavusans', '', 8);

$pdf->AddPage();

/* ==========================
   Heading
========================== */

$pdf->SetFont('dejavusans', 'B', 14);
$pdf->Cell(0, 8, $companyName, 0, 1, 'C');

$pdf->SetFont('dejavusans', 'B', 11);
$pdf->Cell(0, 8, 'Source Followup Report', 0, 1, 'C');

$pdf->Ln(2);

/* ==========================
   Table Header
========================== */

function printHeader($pdf)
{
    $pdf->SetFillColor(220, 220, 220);

    $pdf->SetFont('dejavusans', 'B', 8);

    $pdf->Cell(10, 8, 'S.No', 1, 0, 'C', true);
    $pdf->Cell(22, 8, 'Source No', 1, 0, 'C', true);
    $pdf->Cell(45, 8, 'Source Name', 1, 0, 'C', true);
    $pdf->Cell(28, 8, 'Mobile', 1, 0, 'C', true);
    $pdf->Cell(40, 8, 'Sales Person', 1, 0, 'C', true);
    $pdf->Cell(20, 8, 'Entry', 1, 0, 'C', true);
    $pdf->Cell(24, 8, 'Date', 1, 0, 'C', true);
    $pdf->Cell(24, 8, 'From', 1, 0, 'C', true);
    $pdf->Cell(24, 8, 'To', 1, 0, 'C', true);
    $pdf->Cell(28, 8, 'Followup', 1, 0, 'C', true);
    $pdf->Cell(55, 8, 'Interest', 1, 0, 'C', true);
    $pdf->Cell(20, 8, 'Minutes', 1, 1, 'C', true);

    $pdf->SetFont('dejavusans', '', 8);
}

printHeader($pdf);

/* ==========================
   Query
========================== */

$sql = "
SELECT
    sm.source_no,
    sm.name AS source_name,
    sm.mobile_no AS mobile,
    spm.salespersonname,
    cr.entry_no,
    cr.date,
    cr.`from`,
    cr.`to`,
    cr.followup_date,
    cim.interest,

    COALESCE(
        TIMESTAMPDIFF(
            MINUTE,
            STR_TO_DATE(cr.`from`, '%h:%i %p'),
            STR_TO_DATE(cr.`to`, '%h:%i %p')
        ),
        0
    ) AS totalTime

FROM sourcemaster sm

LEFT JOIN salespersonmaster spm
    ON sm.sales_person_id = spm.id

LEFT JOIN call_register cr
    ON sm.id = cr.source_id

LEFT JOIN customer_interest_master cim
    ON cr.interest = cim.id

WHERE sm.companyid = ?
AND sm.sales_person_id = ?

ORDER BY sm.source_date DESC
";

$stmt = mysqli_prepare($conn, $sql);

mysqli_stmt_bind_param($stmt, "ss", $companyid, $id);

mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

/* ==========================
   Rows
========================== */

$sl = 1;

while ($row = mysqli_fetch_assoc($result)) {

    if ($pdf->GetY() > 185) {
        $pdf->AddPage();
        printHeader($pdf);
    }

    $pdf->Cell(10, 7, $sl++, 1);

    $pdf->Cell(22, 7, $row['source_no'], 1);

    $pdf->Cell(45, 7, mb_strimwidth($row['source_name'], 0, 25, "..."), 1);

    $pdf->Cell(28, 7, $row['mobile'], 1);

    $pdf->Cell(40, 7, mb_strimwidth($row['salespersonname'], 0, 20, "..."), 1);

    $pdf->Cell(20, 7, $row['entry_no'], 1);

    $pdf->Cell(24, 7, $row['date'], 1);

    $pdf->Cell(24, 7, $row['from'], 1);

    $pdf->Cell(24, 7, $row['to'], 1);

    $pdf->Cell(28, 7, $row['followup_date'], 1);

    $pdf->Cell(55, 7, mb_strimwidth($row['interest'], 0, 30, "..."), 1);

    $pdf->Cell(20, 7, $row['totalTime'], 1, 1, 'C');
}

mysqli_stmt_close($stmt);
mysqli_close($conn);

/* ==========================
   Output
========================== */

$pdf->Output('SourceFollowupReport.pdf', 'I');