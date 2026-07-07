<?php
require_once('./vendor/autoload.php');
require_once('./vendor/tecnickcom/tcpdf/tcpdf.php');
include 'conn.php';

$companyid = $_GET['companyid'];

// Query to get product-based sales data - Group by invoice to avoid duplication
$sql = "SELECT 
        h.id,
        h.invoiceno,
        h.date AS sales_date,
        c.name AS sourceName,
        GROUP_CONCAT(pm.productname ORDER BY pm.productname SEPARATOR ', ') AS products,
        sm.salespersonname,
        SUM(id.quantity) AS quantity,
        h.grandtotal AS amount
    FROM invoice_head h
    LEFT JOIN sourcemaster c ON h.customerid = c.id
    LEFT JOIN salespersonmaster sm ON h.addedby = sm.id
    LEFT JOIN invoice_detail id ON h.id = id.headid
    LEFT JOIN productmaster pm ON id.productid = pm.id
    WHERE h.companyid = '$companyid'
    GROUP BY h.id, h.invoiceno, h.date, c.name, sm.salespersonname, h.grandtotal
    ORDER BY h.date DESC, h.id DESC";

$result = mysqli_query($conn, $sql);

// Get totals
$totalRecords = 0;
$totalQty = 0;
$totalAmount = 0;

// Store data
$data = array();
while($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
    $totalRecords++;
    $totalQty += $row['quantity'];
    $totalAmount += $row['amount'];
}

$pdf = new TCPDF('L', 'mm', 'A4');
$pdf->SetCreator('Product Based Sales Report');
$pdf->SetAuthor('Admin');
$pdf->SetTitle('Product Based Sales Report');
$pdf->SetMargins(10, 10, 10);
$pdf->AddPage();

// Build HTML
$html = '
<style>
    .header-table { width: 100%; border-collapse: collapse; margin-bottom: 10px; }
    .header-table td { border: 1px solid #000; padding: 5px; }
    .header-label { font-weight: bold; background-color: #f0f0f0; }
    .data-table { width: 100%; border-collapse: collapse; }
    .data-table th { background-color: #d9edf7; font-weight: bold; border: 1px solid #000; padding: 5px; text-align: center; }
    .data-table td { border: 1px solid #000; padding: 5px; }
</style>

<table class="header-table">
    <tr>
        <td class="header-label" width="12%">Total Records</td>
        <td width="12%">' . $totalRecords . '</td>
        <td class="header-label" width="12%">Total Quantity</td>
        <td width="12%">' . $totalQty . '</td>
        <td class="header-label" width="12%">Total Amount</td>
        <td width="15%">₹' . number_format($totalAmount, 2) . '</td>
    </tr>
</table>

<table class="data-table">
    <tr>
        <th width="30">S.No</th>
        <th width="70">Invoice No</th>
        <th width="70">Sales Date</th>
        <th width="120">Source Name</th>
        <th width="150">Products</th>
        <th width="100">Sales Person</th>
        <th width="40">Qty</th>
        <th width="80">Amount</th>
    </tr>';

$i = 1;
foreach($data as $row) {
    $html .= '
    <tr>
        <td align="center">' . $i++ . '</td>
        <td align="center">' . $row['invoiceno'] . '</td>
        <td align="center">' . date("d/m/Y", strtotime($row['sales_date'])) . '</td>
        <td>' . $row['sourceName'] . '</td>
        <td>' . $row['products'] . '</td>
        <td>' . $row['salespersonname'] . '</td>
        <td align="center">' . $row['quantity'] . '</td>
        <td align="right">₹' . number_format($row['amount'], 2) . '</td>
    </tr>';
}

$html .= '
</table>

<table class="header-table" style="margin-top:10px;">
    <tr>
        <td class="header-label" width="12%">Total Records</td>
        <td width="12%">' . $totalRecords . '</td>
        <td class="header-label" width="12%">Total Qty</td>
        <td width="12%">' . $totalQty . '</td>
        <td class="header-label" width="12%">Total Amount</td>
        <td width="15%">₹' . number_format($totalAmount, 2) . '</td>
    </tr>
</table>

<p style="text-align:right; font-size:10px; margin-top:10px;">
    Product Based Sales Report Generated on: ' . date("d/m/Y H:i") . '
</p>';

$pdf->writeHTML($html, true, false, true, false, '');
$pdf->Output('Product_Based_Sales_Report.pdf', 'I');
?>