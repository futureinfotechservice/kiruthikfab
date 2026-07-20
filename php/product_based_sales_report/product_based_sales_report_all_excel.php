<?php
require_once('./vendor/autoload.php');
include 'conn.php';
include 'cors.php';

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Color;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

// Validate and sanitize inputs
$companyid = isset($_GET['companyid']) ? intval($_GET['companyid']) : 0;
if (empty($companyid)) {
    die('Company ID is required');
}

// Optional date-range filter
$fromDate = isset($_GET['fromdate']) && $_GET['fromdate'] !== '' ? $_GET['fromdate'] : null;
$toDate   = isset($_GET['todate']) && $_GET['todate'] !== '' ? $_GET['todate'] : null;
$search   = isset($_GET['search']) && $_GET['search'] !== '' ? $_GET['search'] : null;
$source   = isset($_GET['source']) ? intval($_GET['source']) : null;
$product  = isset($_GET['product']) ? intval($_GET['product']) : null;
$salesPerson  = isset($_GET['salesperson']) ? intval($_GET['salesperson']) : null;

// ---- Fetch company info ----
$companyName    = 'Company Name';
$companyAddress = '';
$companyPhone   = '';
$companyEmail   = '';

$compSql = "SELECT * FROM companymaster WHERE id = ? LIMIT 1";
$stmt = mysqli_prepare($conn, $compSql);
mysqli_stmt_bind_param($stmt, "i", $companyid);
mysqli_stmt_execute($stmt);
$compResult = mysqli_stmt_get_result($stmt);

if ($compResult && $compRow = mysqli_fetch_assoc($compResult)) {
    $companyName    = !empty($compRow['companyname']) ? $compRow['companyname'] : 'Company Name';
    $companyAddress = !empty($compRow['address']) ? $compRow['address'] : '';
    $companyPhone   = !empty($compRow['contactno']) ? $compRow['contactno'] : '';
    $companyEmail   = !empty($compRow['show_email_id']) ? $compRow['show_email_id'] : '';
}

// ---- Build WHERE clause with proper parameterized queries ----
$whereClauses = array();
$whereClauses[] = "h.companyid = ?";
$params = [$companyid];
$types = "i";

if ($fromDate) {
    $whereClauses[] = "DATE(h.date) >= ?";
    $params[] = $fromDate;
    $types .= "s";
}
if ($toDate) {
    $whereClauses[] = "DATE(h.date) <= ?";
    $params[] = $toDate;
    $types .= "s";
}

// Add source filter
if (!empty($source)) {
    $whereClauses[] = "h.customerid = ?";
    $params[] = $source;
    $types .= "i";
}

// Add sales person filter
if (!empty($salesPerson)) {
    $whereClauses[] = "h.addedby = ?";
    $params[] = $salesPerson;
    $types .= "i";
}

// Add search filter if provided
if (!empty($search)) {
    $searchTerm = "%{$search}%";
    $whereClauses[] = "(h.invoiceno LIKE ? OR c.name LIKE ? OR sm.salespersonname LIKE ?)";
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $types .= "sss";
}

$whereSql = implode(' AND ', $whereClauses);

// ---- First, get the correct total quantity directly from invoice_detail ----
$totalQtySql = "SELECT COALESCE(SUM(id.quantity), 0) as total_qty 
                FROM invoice_detail id
                LEFT JOIN invoice_head h ON h.id = id.headid
                LEFT JOIN sourcemaster c ON h.customerid = c.id
                LEFT JOIN salespersonmaster sm ON h.addedby = sm.id
                WHERE " . $whereSql;

// If product filter is applied, add to total qty query
if (!empty($product)) {
    $totalQtySql .= " AND id.productid = ?";
    $totalQtyParams = array_merge($params, [$product]);
    $totalQtyTypes = $types . "i";
} else {
    $totalQtyParams = $params;
    $totalQtyTypes = $types;
}

$stmt = mysqli_prepare($conn, $totalQtySql);
if ($stmt) {
    mysqli_stmt_bind_param($stmt, $totalQtyTypes, ...$totalQtyParams);
    mysqli_stmt_execute($stmt);
    $totalQtyResult = mysqli_stmt_get_result($stmt);
    $totalQtyRow = mysqli_fetch_assoc($totalQtyResult);
    $actualTotalQty = $totalQtyRow['total_qty'] ?? 0;
    mysqli_stmt_close($stmt);
} else {
    $actualTotalQty = 0;
}

// ---- Query to get product-based sales data ----
$sql = "SELECT 
        h.id,
        h.invoiceno,
        h.date AS sales_date,
        COALESCE(c.name, 'N/A') AS sourceName,
        COALESCE(sm.salespersonname, 'N/A') AS salespersonname,
        COALESCE(SUM(id.quantity), 0) AS quantity,
        COALESCE(h.grandtotal, 0) AS amount
    FROM invoice_head h
    LEFT JOIN sourcemaster c ON h.customerid = c.id
    LEFT JOIN salespersonmaster sm ON h.addedby = sm.id
    LEFT JOIN invoice_detail id ON h.id = id.headid
    WHERE " . $whereSql;

// Add product filter - need to handle differently
if (!empty($product)) {
    $sql .= " AND EXISTS (
        SELECT 1 FROM invoice_detail id2 
        WHERE id2.headid = h.id AND id2.productid = ?
    )";
    $params[] = $product;
    $types .= "i";
}

$sql .= " GROUP BY h.id, h.invoiceno, h.date, c.name, sm.salespersonname, h.grandtotal
          ORDER BY h.date DESC, h.id DESC";

// Prepare and execute the main query
$stmt = mysqli_prepare($conn, $sql);
if (!$stmt) {
    die('Query Error: ' . mysqli_error($conn));
}

mysqli_stmt_bind_param($stmt, $types, ...$params);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if (!$result) {
    die('Query Error: ' . mysqli_error($conn));
}

// Get totals
$totalRecords = 0;
$totalAmount = 0;
$data = array();

while ($row = mysqli_fetch_assoc($result)) {
    // FIXED: Get products for this invoice with correct quantities
    $productSql = "SELECT 
        id.productid,
        pm.productname,
        SUM(id.quantity) as qty
    FROM invoice_detail id
    LEFT JOIN productmaster pm ON id.productid = pm.id
    WHERE id.headid = ?";
    
    $productParams = [$row['id']];
    $productTypes = "i";
    
    // If product filter is applied, only show that product
    if (!empty($product)) {
        $productSql .= " AND id.productid = ?";
        $productParams[] = $product;
        $productTypes .= "i";
    }
    
    $productSql .= " GROUP BY id.productid, pm.productname
                     ORDER BY pm.productname";
    
    $stmt2 = mysqli_prepare($conn, $productSql);
    if ($stmt2) {
        mysqli_stmt_bind_param($stmt2, $productTypes, ...$productParams);
        mysqli_stmt_execute($stmt2);
        $productResult = mysqli_stmt_get_result($stmt2);
        
        // Build products string
        $productsList = array();
        while ($productRow = mysqli_fetch_assoc($productResult)) {
            if (!empty($productRow['productname'])) {
                $productsList[] = $productRow['productname'] . ' (' . $productRow['qty'] . ')';
            }
        }
        
        $row['products'] = !empty($productsList) ? implode(', ', $productsList) : 'No Products';
        mysqli_stmt_close($stmt2);
    } else {
        $row['products'] = 'No Products';
    }
    
    $data[] = $row;
    $totalRecords++;
    $totalAmount += (float)$row['amount'];
}

date_default_timezone_set('Asia/Kolkata');
$generatedOn = date("d/m/Y H:i:s");
$reportTitle = 'Product Based Sales Report';
$reportPeriod = ($fromDate && $toDate)
    ? (date("d/m/Y", strtotime($fromDate)) . ' to ' . date("d/m/Y", strtotime($toDate)))
    : 'All Records';

// ---- Create Excel Spreadsheet ----
try {
    $spreadsheet = new Spreadsheet();
    $sheet = $spreadsheet->getActiveSheet();
    
    // Set default font
    $spreadsheet->getDefaultStyle()->getFont()->setName('Arial')->setSize(10);
    
    // Set column widths
    $columnWidths = [
        'A' => 5,   // S.No
        'B' => 15,  // Invoice No
        'C' => 15,  // Date
        'D' => 20,  // Source
        'E' => 40,  // Products
        'F' => 20,  // Sales Person
        'G' => 10,  // Qty
        'H' => 20   // Amount
    ];
    foreach ($columnWidths as $col => $width) {
        $sheet->getColumnDimension($col)->setWidth($width);
    }
    
    $row = 1;
    
    // ---- DATA TABLE HEADERS ----
    $headers = ['#', 'Invoice No', 'Date', 'Source', 'Products (Qty)', 'Sales Person', 'Qty', 'Amount'];
    $col = 'A';
    foreach ($headers as $header) {
        $sheet->setCellValue($col . $row, $header);
        $col++;
    }
    
    // Style headers
    $headerStyle = [
        'font' => ['bold' => true, 'size' => 10, 'color' => ['rgb' => 'FFFFFF']],
        'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER, 'vertical' => Alignment::VERTICAL_CENTER],
        'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '1976D2']],
        'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]]
    ];
    $sheet->getStyle('A' . $row . ':H' . $row)->applyFromArray($headerStyle);
    $row++;
    
    // ---- DATA ROWS ----
    if (count($data) > 0) {
        $i = 1;
        foreach ($data as $rowData) {
            $sheet->setCellValue('A' . $row, $i++);
            $sheet->setCellValue('B' . $row, $rowData['invoiceno']);
            $sheet->setCellValue('C' . $row, date("d/m/Y", strtotime($rowData['sales_date'])));
            $sheet->setCellValue('D' . $row, $rowData['sourceName']);
            $sheet->setCellValue('E' . $row, $rowData['products']);
            $sheet->setCellValue('F' . $row, $rowData['salespersonname']);
            $sheet->setCellValue('G' . $row, $rowData['quantity']);
            $sheet->setCellValue('H' . $row, $rowData['amount']);
            
            // Set number format for amount
            $sheet->getStyle('H' . $row)->getNumberFormat()->setFormatCode('#,##0.00');
            
            // Apply borders
            $dataStyle = [
                'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]],
                'alignment' => ['vertical' => Alignment::VERTICAL_CENTER]
            ];
            $sheet->getStyle('A' . $row . ':H' . $row)->applyFromArray($dataStyle);
            
            // Align specific columns
            $sheet->getStyle('A' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle('B' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle('C' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle('G' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle('H' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_RIGHT);
            
            // Alternate row colors
            if ($i % 2 == 0) {
                $sheet->getStyle('A' . $row . ':H' . $row)->getFill()
                    ->setFillType(Fill::FILL_SOLID)
                    ->getStartColor()->setRGB('F9F9F9');
            }
            
            $row++;
        }
    } else {
        $sheet->setCellValue('A' . $row, 'No records found for the selected period');
        $sheet->mergeCells('A' . $row . ':H' . $row);
        $sheet->getStyle('A' . $row)->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle('A' . $row)->getFont()->setColor(new Color('757575'));
        $row++;
    }
    
    $row++;
    
    // ---- FOOTER SUMMARY ----
    $footerStartRow = $row;
    
    // Create footer with totals
    $footerData = [
        ['label' => 'Total Records:', 'value' => $totalRecords, 'color' => '1976D2'],
        ['label' => 'Total Qty:', 'value' => number_format($actualTotalQty), 'color' => '388E3C'],
        ['label' => 'Total Amount:', 'value' => '₹ ' . number_format($totalAmount, 2), 'color' => 'F57C00']
    ];
    
    foreach ($footerData as $footer) {
        $sheet->setCellValue('A' . $row, $footer['label']);
        $sheet->mergeCells('A' . $row . ':G' . $row);
        $sheet->setCellValue('H' . $row, $footer['value']);
        
        // Style footer
        $footerStyle = [
            'font' => ['bold' => true, 'size' => 10],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_RIGHT, 'vertical' => Alignment::VERTICAL_CENTER],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'F5F5F5']],
            'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]]
        ];
        $sheet->getStyle('A' . $row . ':H' . $row)->applyFromArray($footerStyle);
        $sheet->getStyle('H' . $row)->getFont()->setColor(new Color($footer['color']));
        
        $row++;
    }
    
    // ---- OUTPUT ----
    $writer = new Xlsx($spreadsheet);
    
    // Clear output buffer
    if (ob_get_length()) {
        ob_end_clean();
    }
    
    // Set headers
    header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    header('Content-Disposition: attachment; filename="Product_Based_Sales_Report_' . date('Ymd_His') . '.xlsx"');
    header('Cache-Control: max-age=0');
    header('Cache-Control: must-revalidate');
    header('Pragma: public');
    
    // Save to output
    $writer->save('php://output');
    
    // Close database connection
    mysqli_close($conn);
    exit;
    
} catch (Exception $e) {
    // Log error and show user-friendly message
    error_log('Excel Generation Error: ' . $e->getMessage());
    die('Error generating report. Please try again or contact support.');
}
?>