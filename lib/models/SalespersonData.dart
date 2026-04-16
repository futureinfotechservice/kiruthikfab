class SalespersonData {
  final String id;
  final String name;
  final int totalCalls;
  final int approach;
  final int kycFilled;
  final String totalTime;
  final double efficiency;
  final String hours;
  final int totalProductSales;
  final double salesPerMin;
  final double avgPerCustomer;
  final int value;
  final int dayTotalOrder;
  final int dayTotalValue;

  SalespersonData({
    required this.id,
    required this.name,
    required this.totalCalls,
    required this.approach,
    required this.kycFilled,
    required this.totalTime,
    required this.efficiency,
    required this.hours,
    required this.totalProductSales,
    required this.salesPerMin,
    required this.avgPerCustomer,
    required this.value,
    this.dayTotalOrder = 0,
    this.dayTotalValue = 0,
  });
}
