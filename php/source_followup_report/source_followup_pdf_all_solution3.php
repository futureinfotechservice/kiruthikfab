<?php
ini_set('memory_limit', '1024M');
set_time_limit(0);

include 'conn.php';
include 'cors.php';
require_once('./vendor/tecnickcom/tcpdf/tcpdf.php');

$companyid = $_GET['companyid'] ?? '';
if (empty($companyid)) {
    die("Company ID is required");
}

class MYPDF extends TCPDF {
    public function Header() {
        $this->SetFont('dejavusans', 'B', 12);
        $this->Cell(0, 8, 'Source Followup Report', 0, 1, 'C');
        $this->Ln(2);

        $this->SetFont('dejavusans', 'B', 8);

        $headers = [
            ['S.No',10],
            ['Source No',22],
            ['Source Name',42],
            ['Mobile',25],
            ['Sales Person',35],
            ['Entry No',18],
            ['Date',22],
            ['Followup',22],
            ['Interest',55]
        ];

        foreach ($headers as $h) {
            $this->Cell($h[1], 8, $h[0], 1, 0, 'C');
        }
        $this->Ln();
    }
}

$pdf = new MYPDF('L', 'mm', 'A4', true, 'UTF-8', false);
$pdf->SetCreator('ERP');
$pdf->SetAuthor('ERP');
$pdf->SetTitle('Source Followup Report');
$pdf->SetMargins(5, 22, 5);
$pdf->SetAutoPageBreak(true, 8);
$pdf->SetFont('dejavusans', '', 7);
$pdf->AddPage();

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
ORDER BY sm.source_date DESC";

$stmt = mysqli_prepare($conn, $sql);
mysqli_stmt_bind_param($stmt, "s", $companyid);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$i = 1;

// column widths
$w = [10,22,42,25,35,18,22,22,55];

while ($row = mysqli_fetch_assoc($result)) {

    // Add page if needed
    if ($pdf->GetY() > 185) {
        $pdf->AddPage();
    }

    $lineHeight = 6;

    // Estimate row height based on longest wrapped column
    $maxLines = 1;
    $texts = [
        $i,
        $row['source_no'],
        $row['source_name'],
        $row['mobile_no'],
        $row['salespersonname'],
        $row['entry_no'],
        $row['date'],
        $row['followup_date'],
        $row['interest']
    ];

    for ($c = 0; $c < count($texts); $c++) {
        $lines = max(1, $pdf->getNumLines((string)$texts[$c], $w[$c]));
        if ($lines > $maxLines) {
            $maxLines = $lines;
        }
    }

    $rowHeight = $maxLines * $lineHeight;
    $x = $pdf->GetX();
    $y = $pdf->GetY();

    for ($c = 0; $c < count($texts); $c++) {
        $pdf->MultiCell(
            $w[$c],
            $rowHeight,
            (string)$texts[$c],
            1,
            'L',
            false,
            0,
            $x,
            $y,
            true,
            0,
            false,
            true,
            $rowHeight,
            'M'
        );
        $x += $w[$c];
    }

    $pdf->SetXY(5, $y + $rowHeight);
    $i++;
}

mysqli_free_result($result);
mysqli_stmt_close($stmt);
mysqli_close($conn);

$pdf->Output('SourceFollowupReport.pdf', 'I');
