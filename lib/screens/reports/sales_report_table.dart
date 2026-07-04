import 'package:flutter/material.dart';

import '../../../models/SalespersonData.dart';

class SalesReportTable extends StatelessWidget {
  final List<SalespersonData> data;

  const SalesReportTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ScrollController horizontalController = ScrollController();

    if (data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          scrollbarOrientation: ScrollbarOrientation.top,
          controller: horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1700,
              child: Column(
                children: [
                  _buildHeader(),
                  ...List.generate(
                    data.length,
                    (index) => _buildRow(data[index], index),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      color: const Color(0xffF8FAFC),
      child: Row(
        children: [
          _header("#", 40),
          _header("SALESPERSON", 200),
          _header("TOTAL CALL", 110),
          _header("APPROACH", 110),
          _header("KYC FILLING", 120),
          _header("TOTAL TIME", 120),
          _header("EFFICIENCY", 120),
          _header("HOURS", 90),
          _header("TOTAL SALES", 120),
          _header("SALES / MIN", 110),
          _header("AVG / CUS", 110),
          _header("VALUE", 120),
          _header("DAY ORDER", 120),
          _header("DAY VALUE", 120),
        ],
      ),
    );
  }

  Widget _header(String text, double width) {
    return Container(
      alignment: Alignment.centerLeft,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xff475569),
        ),
      ),
    );
  }

  String formatIndianAmount(num amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildRow(SalespersonData item, int index) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xffFAFBFC),
        border: const Border(top: BorderSide(color: Color(0xffE5E7EB))),
      ),
      child: Row(
        children: [
          _textCell("${index + 1}", 40),

          /// Salesperson
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _avatarColor(index),
                    child: Text(
                      _getInitials(item.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _metricCell(item.totalCalls, item.totalCalls / 70, Colors.blue, 110),

          _metricCell(
            item.approach,
            item.approach / 70,
            Colors.deepPurple,
            110,
          ),

          _metricCell(item.kycFilled, item.kycFilled / 70, Colors.green, 120),

          _timeCell(item.totalTime, 120),

          _efficiencyCell(item.efficiency, 120),

          _hoursCell(item.hours, 90),

          _metricCell(
            item.totalProductSales,
            item.totalProductSales / 250,
            Colors.orange,
            120,
          ),

          _badgeCell(
            item.salesPerMin.toStringAsFixed(2),
            Colors.green.shade50,
            Colors.green,
            110,
          ),

          _badgeCell(
            item.avgPerCustomer.toStringAsFixed(1),
            Colors.blue.shade50,
            Colors.blue,
            110,
          ),

          _amountCell('₹${formatIndianAmount(item.value as num)}', 120),

          _amountCell(item.dayTotalOrder.toString(), 120),

          _amountCell("₹${item.dayTotalValue}", 120),
        ],
      ),
    );
  }

  Widget _textCell(String value, double width) {
    return SizedBox(
      width: width,
      child: Center(child: Text(value, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _metricCell(int value, double progress, Color color, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              height: 4,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCell(String time, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(time),
        ],
      ),
    );
  }

  Widget _hoursCell(String hours, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.timelapse, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(hours),
        ],
      ),
    );
  }

  Widget _badgeCell(String text, Color bg, Color color, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: .2)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _efficiencyCell(double efficiency, double width) {
    Color bg;
    Color text;
    String label;

    if (efficiency >= 95) {
      bg = Colors.green.shade100;
      text = Colors.green;
      label = "Excellent";
    } else if (efficiency >= 80) {
      bg = Colors.blue.shade100;
      text = Colors.blue;
      label = "Good";
    } else {
      bg = Colors.orange.shade50;
      text = Colors.orange;
      label = "Average";
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${efficiency.toStringAsFixed(1)}%",
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: text, fontSize: 10)),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.split(" ");

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}";
    }

    return parts[0][0];
  }

  Color _avatarColor(int index) {
    List<Color> colors = [
      Colors.orange,
      Colors.indigo,
      Colors.green,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.amber,
      Colors.teal,
    ];

    return colors[index % colors.length];
  }
}
