import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state_controller.dart';
import '../widgets/delivery_stepper.dart';

class RiderLiveMapScreen extends StatefulWidget {
  final CentralOrder trip;
  final void Function(String orderId, double payout) onCompleteOrder;

  const RiderLiveMapScreen({
    super.key,
    required this.trip,
    required this.onCompleteOrder,
  });

  @override
  State<RiderLiveMapScreen> createState() => _RiderLiveMapScreenState();
}

class _RiderLiveMapScreenState extends State<RiderLiveMapScreen> with TickerProviderStateMixin {
  static const Color brandGreen = Color(0xFF32BB78);

  late final AnimationController _progressController;
  late final Animation<double> _progress;
  late final AnimationController _pulseController;

  double _zoom = 1.0;
  double _lastProgressTarget = 0.0;
  String _currentStep = 'Accepted'; // 'Accepted' | 'Arrived' | 'Picked Up'

  // A stable-but-varied curve offset per order so routes don't all look identical.
  late final double _curveSeed;

  @override
  void initState() {
    super.initState();
    _curveSeed = (widget.trip.id.hashCode % 100) / 100.0;

    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _progress = CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

    _lastProgressTarget = _targetForStep(_currentStep);
    _progressController.value = _lastProgressTarget;
  }

  void _advanceStep() {
    setState(() {
      if (_currentStep == 'Accepted') {
        _currentStep = 'Arrived';
      } else if (_currentStep == 'Arrived') {
        _currentStep = 'Picked Up';
      } else if (_currentStep == 'Picked Up') {
        final double payout = double.parse((widget.trip.total * 0.15).toStringAsFixed(2));
        widget.onCompleteOrder(widget.trip.id, payout);
        Navigator.of(context).pop();
        return;
      }
      final double newTarget = _targetForStep(_currentStep);
      _progressController.animateTo(newTarget, curve: Curves.easeInOutCubic);
      _lastProgressTarget = newTarget;
    });
  }

  double _targetForStep(String step) {
    switch (step) {
      case 'Accepted':
        return 0.46; // en route to the vendor to collect the order
      case 'Arrived':
        return 0.5; // exactly at the vendor pin
      case 'Picked Up':
        return 0.97; // heading to the customer, almost there
      default:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double get _totalDistanceKm => 1.8 + (_curveSeed * 2.4);

  double get _remainingKm {
    final double remainFrac = (1 - _progress.value).clamp(0.0, 1.0);
    return (_totalDistanceKm * remainFrac).clamp(0.0, _totalDistanceKm);
  }

  int get _etaMinutes {
    const double avgSpeedKmh = 22.0;
    final double mins = (_remainingKm / avgSpeedKmh) * 60;
    return mins.ceil().clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final double payout = double.parse((trip.total * 0.15).toStringAsFixed(2));

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F1),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_progress, _pulseController]),
              builder: (context, _) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 2.2,
                  child: Transform.scale(
                    scale: _zoom,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _LiveRoutePainter(
                        vendorFrac: Offset(trip.vendorMapX, trip.vendorMapY),
                        buyerFrac: Offset(trip.dropMapX, trip.dropMapY),
                        progress: _progress.value,
                        pulse: _pulseController.value,
                        curveSeed: _curveSeed,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top bar: back button + safety/report action.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_rounded, size: 15, color: brandGreen),
                          const SizedBox(width: 4),
                          Text('${_remainingKm.toStringAsFixed(1)} km · $_etaMinutes min', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    _circleButton(Icons.sos_rounded, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Safety line dialed. Stay safe out there!'), behavior: SnackBarBehavior.floating),
                      );
                    }, color: Colors.red),
                  ],
                ),
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 300,
            child: Column(
              children: [
                _zoomButton(Icons.add_rounded, () => setState(() => _zoom = (_zoom + 0.2).clamp(0.7, 2.0))),
                const SizedBox(height: 8),
                _zoomButton(Icons.remove_rounded, () => setState(() => _zoom = (_zoom - 0.2).clamp(0.7, 2.0))),
                const SizedBox(height: 8),
                _zoomButton(Icons.my_location_rounded, () => setState(() => _zoom = 1.0)),
              ],
            ),
          ),

          // Bottom trip card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  DeliveryStepper(currentStep: _currentStep),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(_currentStep == 'Picked Up' ? Icons.location_on_rounded : Icons.storefront_rounded, size: 18, color: brandGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentStep == 'Picked Up' ? trip.dropoffLocation : trip.pickupLocation,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('GHS ${payout.toStringAsFixed(2)}', style: GoogleFonts.inter(color: brandGreen, fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${trip.items.length} item${trip.items.length == 1 ? '' : 's'} · ${trip.vendorName} · ${trip.paymentMethod}',
                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${trip.vendorName}...'), behavior: SnackBarBehavior.floating),
                          ),
                          icon: const Icon(Icons.storefront_rounded, size: 16),
                          label: Text('Vendor', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calling customer...'), behavior: SnackBarBehavior.floating),
                          ),
                          icon: const Icon(Icons.person_rounded, size: 16),
                          label: Text('Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: _advanceStep,
                      child: Text(
                        _currentStep == 'Accepted'
                            ? 'Arrived at Vendor'
                            : _currentStep == 'Arrived'
                                ? 'Collected — Head to Customer'
                                : 'Complete Delivery',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color color = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)]),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}

class _LiveRoutePainter extends CustomPainter {
  final Offset vendorFrac;
  final Offset buyerFrac;
  final double progress;
  final double pulse;
  final double curveSeed;

  static const Color brandGreen = Color(0xFF32BB78);

  _LiveRoutePainter({
    required this.vendorFrac,
    required this.buyerFrac,
    required this.progress,
    required this.pulse,
    required this.curveSeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    // Rider "starting point" (off toward a corner) for the first leg of the trip.
    final Offset riderStartFrac = Offset(
      (vendorFrac.dx + (curveSeed > 0.5 ? -0.22 : 0.22)).clamp(0.03, 0.97),
      (vendorFrac.dy + (curveSeed > 0.5 ? 0.2 : -0.2)).clamp(0.03, 0.97),
    );

    final Offset riderStart = Offset(riderStartFrac.dx * size.width, riderStartFrac.dy * size.height);
    final Offset vendorPoint = Offset(vendorFrac.dx * size.width, vendorFrac.dy * size.height);
    final Offset buyerPoint = Offset(buyerFrac.dx * size.width, buyerFrac.dy * size.height);

    final Path leg1 = _curvedPath(riderStart, vendorPoint, curveSeed);
    final Path leg2 = _curvedPath(vendorPoint, buyerPoint, 1 - curveSeed);

    // Draw full route (untraveled) as dashed grey guide.
    _drawDashed(canvas, leg1, Colors.grey.shade400);
    _drawDashed(canvas, leg2, Colors.grey.shade400);

    // Draw traveled portion in solid green, and find current marker position.
    Offset markerPos;
    double markerAngle;

    if (progress <= 0.5) {
      final double localT = (progress / 0.5).clamp(0.0, 1.0);
      final metrics = leg1.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final traveled = metric.extractPath(0, metric.length * localT);
        _drawSolid(canvas, traveled);
        final tangent = metric.getTangentForOffset(metric.length * localT);
        markerPos = tangent?.position ?? riderStart;
        markerAngle = tangent?.angle ?? 0;
      } else {
        markerPos = riderStart;
        markerAngle = 0;
      }
    } else {
      _drawSolid(canvas, leg1);
      final double localT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final metrics = leg2.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final traveled = metric.extractPath(0, metric.length * localT);
        _drawSolid(canvas, traveled);
        final tangent = metric.getTangentForOffset(metric.length * localT);
        markerPos = tangent?.position ?? vendorPoint;
        markerAngle = tangent?.angle ?? 0;
      } else {
        markerPos = vendorPoint;
        markerAngle = 0;
      }
    }

    _drawPin(canvas, riderStart, Icons.circle, Colors.blueGrey, small: true);
    _drawPin(canvas, vendorPoint, Icons.storefront_rounded, brandGreen);
    _drawPin(canvas, buyerPoint, Icons.home_rounded, Colors.redAccent);
    _drawRiderMarker(canvas, markerPos, markerAngle);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFEFF3F1));

    final blockPaint = Paint()..color = const Color(0xFFE2E9E4);
    final rng = Random(42);
    for (int i = 0; i < 26; i++) {
      final double bw = 26 + rng.nextDouble() * 46;
      final double bh = 26 + rng.nextDouble() * 46;
      final double bx = rng.nextDouble() * size.width;
      final double by = rng.nextDouble() * size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(6)),
        blockPaint,
      );
    }

    final roadPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round;
    final roadBorder = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = StrokeCap.round;

    final List<Path> roads = [
      Path()..moveTo(0, size.height * 0.22)..lineTo(size.width, size.height * 0.22),
      Path()..moveTo(0, size.height * 0.58)..lineTo(size.width, size.height * 0.58),
      Path()..moveTo(0, size.height * 0.85)..lineTo(size.width, size.height * 0.85),
      Path()..moveTo(size.width * 0.15, 0)..lineTo(size.width * 0.15, size.height),
      Path()..moveTo(size.width * 0.5, 0)..lineTo(size.width * 0.5, size.height),
      Path()..moveTo(size.width * 0.82, 0)..lineTo(size.width * 0.82, size.height),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadBorder);
      canvas.drawPath(road, roadPaint);
    }
  }

  Path _curvedPath(Offset from, Offset to, double seed) {
    final Offset mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final double dx = to.dx - from.dx;
    final double dy = to.dy - from.dy;
    final double len = sqrt(dx * dx + dy * dy);
    if (len == 0) return Path()..moveTo(from.dx, from.dy);

    // Perpendicular offset, magnitude/direction varied by seed for visual variety.
    final Offset perp = Offset(-dy / len, dx / len);
    final double bend = (seed - 0.5) * len * 0.5;
    final Offset control = mid + perp * bend;

    return Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  void _drawDashed(Canvas canvas, Path path, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const double dashLen = 8;
      const double gapLen = 7;
      while (distance < metric.length) {
        final double next = (distance + dashLen).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  void _drawSolid(Canvas canvas, Path path) {
    final glowPaint = Paint()
      ..color = brandGreen.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final linePaint = Paint()..color = brandGreen..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawPin(Canvas canvas, Offset pos, IconData icon, Color color, {bool small = false}) {
    if (small) {
      canvas.drawCircle(pos, 6, Paint()..color = color);
      canvas.drawCircle(pos, 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      return;
    }

    canvas.drawCircle(pos, 18, Paint()..color = Colors.black.withOpacity(0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(pos, 16, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 16, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.4);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontSize: 16, fontFamily: icon.fontFamily, color: color, package: icon.fontPackage),
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawRiderMarker(Canvas canvas, Offset pos, double angle) {
    // Pulsing "live" halo to sell the sense of continuous GPS movement.
    final double haloRadius = 14 + pulse * 14;
    canvas.drawCircle(pos, haloRadius, Paint()..color = brandGreen.withOpacity((1 - pulse) * 0.35));

    canvas.drawCircle(pos, 15, Paint()..color = Colors.black.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(pos, 14, Paint()..color = brandGreen);
    canvas.drawCircle(pos, 14, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.4);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    const IconData bikeIcon = Icons.directions_bike_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(bikeIcon.codePoint),
      style: TextStyle(fontSize: 16, fontFamily: bikeIcon.fontFamily, color: Colors.white, package: bikeIcon.fontPackage),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}
