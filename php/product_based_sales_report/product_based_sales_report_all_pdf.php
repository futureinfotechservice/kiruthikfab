<?php
require_once('./vendor/autoload.php');
require_once('./vendor/tecnickcom/tcpdf/tcpdf.php');
include 'conn.php';

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

// Add product filter
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
    // Get products for this invoice with correct quantities
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

// ---- Custom PDF class ----
class MYPDF extends TCPDF {
    public $reportCompanyName    = '';
    public $reportCompanyAddress = '';
    public $reportContactLine    = '';
    public $reportTitle          = '';
    public $reportGeneratedOn    = '';
    public $reportPeriod         = '';
    public $totalRecords         = 0;
    public $totalAmount          = 0;
    public $actualTotalQty       = 0;
    public $data                 = array();

    public function Header() {
        // Header content handled in HTML
    }

    public function Footer() {
        $this->SetY(-15);
        $this->SetFont('dejavusans', '', 8);
        $this->SetTextColor(117, 117, 117);
        
        $this->Cell(0, 10, 'Page ' . $this->getAliasNumPage() . ' of ' . $this->getAliasNbPages(), 0, false, 'C', 0, '', 0, false, 'T', 'M');
    }
}

// ---- Create PDF ----
$pdf = new MYPDF('L', 'mm', 'A4', true, 'UTF-8', false);

// Set document information
$pdf->SetCreator('Product Based Sales Report');
$pdf->SetAuthor('Admin');
$pdf->SetTitle($reportTitle);
$pdf->SetSubject($reportTitle);

// Remove default header
$pdf->setPrintHeader(false);
$pdf->setPrintFooter(true);

// Set margins
$pdf->SetMargins(10, 10, 10);
$pdf->SetAutoPageBreak(true, 25);

// Add page
$pdf->AddPage();

// Set font
$pdf->SetFont('dejavusans', '', 8);

// Assign properties
$pdf->reportCompanyName    = $companyName;
$pdf->reportCompanyAddress = $companyAddress;

$contactParts = array();
if (!empty($companyPhone)) $contactParts[] = 'Tel: ' . $companyPhone;
if (!empty($companyEmail)) $contactParts[] = 'Email: ' . $companyEmail;
$pdf->reportContactLine = implode(' | ', $contactParts);
$pdf->reportTitle       = $reportTitle;
$pdf->reportGeneratedOn = $generatedOn;
$pdf->reportPeriod      = $reportPeriod;
$pdf->totalRecords      = $totalRecords;
$pdf->totalAmount       = $totalAmount;
$pdf->actualTotalQty    = $actualTotalQty;
$pdf->data              = $data;

// ---- Build HTML content ----
$html = '
<style>
    .header-table { width: 100%; border-bottom: 2px solid #1976D2; padding-bottom: 5px; margin-bottom: 8px; }
    .company-name { font-size: 16px; font-weight: bold; color: #0D47A1; }
    .company-details { font-size: 8px; color: #616161; }
    .report-title { font-size: 14px; font-weight: bold; color: #1976D2; }
    .report-info { font-size: 7px; color: #757575; }
    
    .summary-table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
    .summary-cell { background-color: #F5F5F5; text-align: center; padding: 6px; border: 1px solid #E0E0E0; }
    .summary-label { font-size: 8px; color: #616161; }
    .summary-value { font-size: 14px; font-weight: bold; }
    .summary-value.blue { color: #1976D2; }
    .summary-value.green { color: #388E3C; }
    .summary-value.orange { color: #F57C00; }
    
    .data-table { width: 100%; border-collapse: collapse; }
    .data-table th { 
        background-color: #1976D2; 
        color: #FFFFFF; 
        font-weight: bold; 
        border: 0.5px solid #BDBDBD; 
        padding: 5px; 
        text-align: center; 
        font-size: 9px;
    }
    .data-table td { 
        border: 0.5px solid #BDBDBD; 
        padding: 4px;
        text-align: left; 
        font-size: 8px;
    }
    .data-table tr:nth-child(even) { background-color: #F9F9F9; }
    
    .footer-summary { 
        width: 100%; 
        background-color: #F5F5F5; 
        margin-top: 8px; 
        border: 1px solid #E0E0E0; 
        padding: 6px;
    }
    .footer-summary td { 
        text-align: right; 
        padding: 4px 8px; 
        font-size: 9px; 
        font-weight: bold; 
    }
</style>

<!-- Header -->
<table class="header-table">
    <tr>
        <td width="60%" style="vertical-align:top;">
            <div class="company-name">' . htmlspecialchars($pdf->reportCompanyName, ENT_QUOTES, 'UTF-8') . '</div>
            <div class="company-details">' . htmlspecialchars($pdf->reportCompanyAddress, ENT_QUOTES, 'UTF-8') . '</div>
            <div class="company-details">' . htmlspecialchars($pdf->reportContactLine, ENT_QUOTES, 'UTF-8') . '</div>
        </td>
        <td width="40%" style="text-align:right; vertical-align:top;">
            <div class="report-title">' . htmlspecialchars($pdf->reportTitle, ENT_QUOTES, 'UTF-8') . '</div>
            <div class="report-info">Generated on: ' . htmlspecialchars($pdf->reportGeneratedOn, ENT_QUOTES, 'UTF-8') . '</div>
            <div class="report-info">Period: ' . htmlspecialchars($pdf->reportPeriod, ENT_QUOTES, 'UTF-8') . '</div>
        </td>
    </tr>
</table>

<!-- Summary Cards -->
<table class="summary-table">
    <tr>
        <td class="summary-cell" width="33%">
            <div class="summary-label">Total Records</div>
            <div class="summary-value blue">' . number_format($pdf->totalRecords) . '</div>
        </td>
        <td class="summary-cell" width="33%">
            <div class="summary-label">Total Quantity</div>
            <div class="summary-value green">' . number_format($pdf->actualTotalQty) . '</div>
        </td>
        <td class="summary-cell" width="34%">
            <div class="summary-label">Total Amount</div>
            <div class="summary-value orange">₹ ' . number_format($pdf->totalAmount, 2) . '</div>
        </td>
    </tr>
</table>

<!-- Data Table -->
<table class="data-table">
    <thead>
        <tr>
            <th width="5%">#</th>
            <th width="10%">Invoice</th>
            <th width="10%">Date</th>
            <th width="15%">Source</th>
            <th width="25%">Products (Qty)</th>
            <th width="13%">Sales Person</th>
            <th width="7%">Qty</th>
            <th width="15%">Amount</th>
        </tr>
    </thead>
    <tbody>';

if (count($pdf->data) > 0) {
    $i = 1;
    foreach ($pdf->data as $row) {
        $html .= '
        <tr>
            <td width="5%" align="center">' . $i++ . '</td>
            <td width="10%" align="center">' . htmlspecialchars($row['invoiceno'], ENT_QUOTES, 'UTF-8') . '</td>
            <td width="10%" align="center">' . date("d/m/Y", strtotime($row['sales_date'])) . '</td>
            <td width="15%">' . htmlspecialchars($row['sourceName'], ENT_QUOTES, 'UTF-8') . '</td>
            <td width="25%">' . htmlspecialchars($row['products'], ENT_QUOTES, 'UTF-8') . '</td>
            <td width="13%">' . htmlspecialchars($row['salespersonname'], ENT_QUOTES, 'UTF-8') . '</td>
            <td width="7%" align="center">' . number_format($row['quantity']) . '</td>
            <td width="15%" align="right">₹ ' . number_format($row['amount'], 2) . '</td>
        </tr>';
    }
} else {
    $html .= '
    <tr>
        <td colspan="8" align="center" style="padding: 20px; color: #757575;">
            No records found for the selected period
        </td>
    </tr>';
}

$html .= '
    </tbody>
</table>

<!-- Footer Summary -->
<table class="footer-summary">
    <tr>
        <td align="right">
            <span style="color: #1976D2;">Total Records: ' . number_format($pdf->totalRecords) . '</span> &nbsp;|&nbsp;
            <span style="color: #388E3C;">Total Qty: ' . number_format($pdf->actualTotalQty) . '</span> &nbsp;|&nbsp;
            <span style="color: #F57C00;">Total Amount: ₹ ' . number_format($pdf->totalAmount, 2) . '</span>
        </td>
    </tr>
</table>';

// Write HTML
$pdf->writeHTML($html, true, false, true, false, '');

// Close and output PDF
try {
    // Clear output buffer if any
    if (ob_get_length()) {
        ob_end_clean();
    }
    
    // Output PDF
    $pdf->Output('Product_Based_Sales_Report_' . date('Ymd_His') . '.pdf', 'I');
    
} catch (Exception $e) {
    // Log error and show user-friendly message
    error_log('PDF Generation Error: ' . $e->getMessage());
    die('Error generating PDF report. Please try again or contact support.');
}

// Close database connection
mysqli_close($conn);
?>