import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableOrdersScreen extends StatefulWidget {
  final List<Map<String, String>> availableJobs;
  final Map<String, String>? ongoingJob;
  final Function(Map<String, String>) onAcceptJob;
  final VoidCallback? onResumeTrip;

  const AvailableOrdersScreen({
    super.key,
    required this.availableJobs,
    required this.ongoingJob,
    required this.onAcceptJob,
    this.onResumeTrip,
  });

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Elegant customized Vector map background
          Container(
            color: const Color(0xFFF0F4F8),
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: MapRoadsPainter(hasActiveRoute: widget.ongoingJob != null),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.ongoingJob != null) ...[
                  _buildResumeTripBanner(widget.ongoingJob!),
                  const SizedBox(height: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_tethering, color: Color(0xFF32BB78)),
                        const SizedBox(width: 12),
                        Text('Looking for live jobs...', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: widget.availableJobs.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
                            child: Text('No dispatch routes open yet.\nOrders prepared by the kitchen will pop up here!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey, height: 1.4)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.availableJobs.length,
                          itemBuilder: (context, idx) {
                            final job = widget.availableJobs[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Order #${job['id']}', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
                                      Text('GHS ${job['payout']}', style: GoogleFonts.inter(color: const Color(0xFF32BB78), fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(children: [const Icon(Icons.storefront, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(job['vendorName']!, style: const TextStyle(fontWeight: FontWeight.bold)))]),
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(job['drop']!, style: const TextStyle(color: Colors.grey)))]),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF32BB78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      onPressed: widget.ongoingJob != null ? null : () => widget.onAcceptJob(job),
                                      child: Text('Accept Offer Route', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeTripBanner(Map<String, String> ongoingJob) {
    return GestureDetector(
      onTap: widget.onResumeTrip,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF32BB78), Color(0xFF23945E)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF32BB78).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip in progress · ${ongoingJob['vendorName']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Tap to reopen the live map', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class MapRoadsPainter extends CustomPainter {
  final bool hasActiveRoute;
  MapRoadsPainter({required this.hasActiveRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 20..strokeCap = StrokeCap.round;
    final borderPaint = Paint()..color = Colors.grey.shade200..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.round;

    List<Path> mapPaths = [
      Path()..moveTo(0, 280)..lineTo(size.width, 280),
      Path()..moveTo(110, 0)..lineTo(110, size.height),
    ];

    for (var path in mapPaths) {
      canvas.drawPath(path, borderPaint);
      canvas.drawPath(path, roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
