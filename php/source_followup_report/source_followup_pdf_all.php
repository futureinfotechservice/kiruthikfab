<?php

include 'conn.php';
include 'cors.php';

require_once('tcpdf/tcpdf.php');

$companyid = $_GET['companyid'] ?? '';

if (empty($companyid)) {
    die("Company ID is required");
}

$pdf = new TCPDF('L', 'mm', 'A4', true, 'UTF-8', false);

$pdf->SetCreator('ERP');
$pdf->SetAuthor('ERP');
$pdf->SetTitle('Source Followup Report');
$pdf->SetMargins(5, 5, 5);
$pdf->SetAutoPageBreak(true, 5);
$pdf->SetFont('dejavusans', '', 8);

$pdf->AddPage();

$html = '
<h3 align="center">Source Followup Report</h3>

<table border="1" cellpadding="3">
<tr style="font-weight:bold;background-color:#dddddd;">
    <th width="25">S.No</th>
    <th width="60">Source No</th>
    <th width="120">Source Name</th>
    <th width="80">Mobile</th>
    <th width="100">Sales Person</th>
    <th width="60">Entry No</th>
    <th width="70">Date</th>
    <th width="70">Followup</th>
    <th width="120">Interest</th>
</tr>
';

$sql = "
SELECT
    sm.source_no,
    sm.name AS source_name,
    sm.mobile_no,
    spm.salespersonname,
    cr.entry_no,
    cr.date,
    cr.followup_date,
    cim.interest

FROM sourcemaster sm

LEFT JOIN salespersonmaster spm
ON sm.sales_person_id = spm.id

LEFT JOIN call_register cr
ON sm.id = cr.source_id

LEFT JOIN customer_interest_master cim
ON cr.interest = cim.id

WHERE sm.companyid = ?

ORDER BY sm.source_date DESC
";

$stmt = mysqli_prepare($conn, $sql);
mysqli_stmt_bind_param($stmt, "s", $companyid);
mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

$i = 1;

while ($row = mysqli_fetch_assoc($result)) {

    $html .= '
    <tr>
        <td>'.$i++.'</td>
        <td>'.$row['source_no'].'</td>
        <td>'.$row['source_name'].'</td>
        <td>'.$row['mobile_no'].'</td>
        <td>'.$row['salespersonname'].'</td>
        <td>'.$row['entry_no'].'</td>
        <td>'.$row['date'].'</td>
        <td>'.$row['followup_date'].'</td>
        <td>'.$row['interest'].'</td>
    </tr>';
}

$html .= '</table>';

$pdf->writeHTML($html, true, false, true, false, '');

$pdf->Output('SourceFollowupReport.pdf', 'I');