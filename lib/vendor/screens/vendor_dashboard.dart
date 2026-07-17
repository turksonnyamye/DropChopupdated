import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state_controller.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> with SingleTickerProviderStateMixin {
  static const Color accent = Color(0xFF0EA37A);
  static const Color accentGlow = Color(0xFF6EFFC4);

  final DropChopStateController _controller = DropChopStateController();
  String selectedRange = '7D';
  int? selectedPointIndex;
  bool isRefreshing = false;
  static const double platformCommissionRate = 0.18;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;

    final String? vendorId = VendorSession.currentVendorId;
    final List<CentralOrder> vendorOrders =
        vendorId != null ? _controller.ordersForVendor(vendorId) : _controller.orders;
    final List<CentralOrder> completedOrders =
        vendorOrders.where((o) => o.status == OrderState.delivered).toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    // Financial Reconciliation Module calculation (18% standard platform commission)
    double grossEarnings = completedOrders.fold(0.0, (sum, order) => sum + order.total);
    double netPayout = grossEarnings * (1 - platformCommissionRate);

    final List<double> chartData = completedOrders.isEmpty
        ? [0, 0]
        : completedOrders.length == 1
            ? [0, completedOrders.first.total]
            : completedOrders.reversed.map((o) => o.total).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07080A) : const Color(0xFFF3F5F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Financials', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: textPrimary)),
            Text(VendorSession.currentVendorName ?? '', style: GoogleFonts.inter(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENDING PAYOUT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('GHS ${netPayout.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Gross: GHS ${grossEarnings.toStringAsFixed(2)} | Platform Comm: ${(platformCommissionRate * 100).toInt()}%',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Gross Metrics', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomPaint(
                painter: _SparklinePainter(chartData, accent, accentGlow, selectedPointIndex),
              ),
            ),
            const SizedBox(height: 24),
            Text('Transactions Ledger', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            if (completedOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text('No completed sales yet.', style: GoogleFonts.inter(color: textSecondary)),
                ),
              )
            else
              ...completedOrders.map((order) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${order.id}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textPrimary)),
                        Text('${order.items.length} items • Delivered', style: GoogleFonts.inter(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                    Text('+ GHS ${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(color: accent, fontWeight: FontWeight.w900)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color accent;
  final Color glow;
  final int? highlightIndex;

  _SparklinePainter(this.data, this.accent, this.glow, this.highlightIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final widthStep = size.width / (data.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((data[i] - minVal) / range) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withOpacity(0.35), accent.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [accent, glow]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawCircle(points.last, 6, Paint()..color = glow.withOpacity(0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(points.last, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}