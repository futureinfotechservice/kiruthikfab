<?php
require './vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

include 'conn.php';

$companyid=$_GET['companyid'];

$sql="SELECT
        h.id,
        h.invoiceno,
        h.customerid,
        c.name AS sourceName,
        c.mobile_no,
        h.date,
        h.grandtotal AS total,
        h.addedby,
        h.created_at,
        (SELECT COUNT(*) FROM invoice_detail WHERE headid = h.id) AS total_items,
        GROUP_CONCAT(DISTINCT pm.productname ORDER BY pm.productname SEPARATOR ', ') AS products,
        sm.salespersonname
    FROM invoice_head h
    LEFT JOIN sourcemaster c ON h.customerid=c.id
    LEFT JOIN salespersonmaster sm ON h.addedby=sm.id
    LEFT JOIN invoice_detail id ON h.id=id.headid
    LEFT JOIN productmaster pm ON id.productid=pm.id
    WHERE h.companyid='$companyid'
    GROUP BY h.id";

$result=mysqli_query($conn,$sql);

$spreadsheet=new Spreadsheet();
$sheet=$spreadsheet->getActiveSheet();

$sheet->setCellValue('A1','S.No');
$sheet->setCellValue('B1','Invoice No');
$sheet->setCellValue('C1','Date');
$sheet->setCellValue('D1','Customer');
$sheet->setCellValue('E1','Mobile');
$sheet->setCellValue('F1','Products');
$sheet->setCellValue('G1','Sales Person');
$sheet->setCellValue('H1','Items');
$sheet->setCellValue('I1','Total');

$rowNo=2;
$i=1;
$grand=0;

while($row=mysqli_fetch_assoc($result))
{
    $sheet->setCellValue('A'.$rowNo,$i++);
    $sheet->setCellValue('B'.$rowNo,$row['invoiceno']);
    $sheet->setCellValue('C'.$rowNo,$row['date']);
    $sheet->setCellValue('D'.$rowNo,$row['sourceName']);
    $sheet->setCellValue('E'.$rowNo,$row['mobile_no']);
    $sheet->setCellValue('F'.$rowNo,$row['products']);
    $sheet->setCellValue('G'.$rowNo,$row['salespersonname']);
    $sheet->setCellValue('H'.$rowNo,$row['total_items']);
    $sheet->setCellValue('I'.$rowNo,$row['total']);

    $grand += $row['total'];
    $rowNo++;
}

$sheet->setCellValue('H'.$rowNo,'Grand Total');
$sheet->setCellValue('I'.$rowNo,$grand);

foreach(range('A','I') as $col)
{
    $sheet->getColumnDimension($col)->setAutoSize(true);
}

header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
header('Content-Disposition: attachment;filename="Invoice_Report.xlsx"');
header('Cache-Control: max-age=0');

$writer=new Xlsx($spreadsheet);
$writer->save('php://output');
exit;